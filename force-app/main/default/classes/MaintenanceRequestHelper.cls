public with sharing class MaintenanceRequestHelper {
    
    /**
     * When an existing maintenance request of type Repair or Routine Maintenance is closed, 
     * create a new maintenance request for a future routine checkup
     */
    public static void createMaintenanceRequest(Map<Id, Case> cases){
        System.debug('createMaintenanceRequest');
        // When an existing maintenance request of type Repair or Routine Maintenance is closed, create a new maintenance request for a future routine checkup.
        List<Case> newRequests = new List<Case>();
        List<Equipment_Maintenance_Item__c> itemListToInsert = new List<Equipment_Maintenance_Item__c>();
        List<AggregateResult> caseMaintenanceCycleList = [SELECT Maintenance_Request__c, 
            MIN(Equipment__r.Maintenance_Cycle__c) shortest 
            FROM Equipment_Maintenance_Item__c GROUP BY Maintenance_Request__c];
        Map<Id, Integer> caseMaintenanceCycle = new Map<Id,Integer>();
        for(AggregateResult ar : caseMaintenanceCycleList){
            caseMaintenanceCycle.put((Id) ar.get('Maintenance_Request__c'), Integer.valueOf(ar.get('shortest')));
        }
        // fetch all maintenance items to be cloned for new request.
        Map<String, List<Equipment_Maintenance_Item__c>> maintenanceItemMap = getMaintenanceItems(cases.values());
        for(Case c : cases.values()){
            if((c.Type == 'Repair' || c.Type == 'Routine Maintenance') && c.Status == 'Closed' ){
                // Calculate the maintenance request due dates by using the maintenance cycle defined on the related equipment records. 
                // If multiple pieces of equipment are used in the maintenance request, 
                // define the due date by applying the shortest maintenance cycle to today’s date.
                Integer maintenanceCycle = caseMaintenanceCycle.get(c.Id);
                
                Case futureCheckup = new Case(
                    Status = 'New',
                    Origin = 'Web',
                    ParentId = c.Id,
                    Vehicle__c = c.Vehicle__c,  // This new maintenance request is tied to the same Vehicle
                    Product__c = c.Product__c,
                    Type = 'Routine Maintenance',
                    Subject = 'Routine checkup',
                    Date_Reported__c = System.today(),
                    Date_Due__c = System.today().addDays(maintenanceCycle)
                );
                newRequests.add(futureCheckup);
            }
        }

        if(!newRequests.isEmpty()){
            insert newRequests;

            for (Case insertedCase : newRequests) {
                List<Equipment_Maintenance_Item__c> itemList = maintenanceItemMap.get(insertedCase.ParentId);
                if (itemList.size()>0) {
                    for (Equipment_Maintenance_Item__c item : itemList) {
                        Equipment_Maintenance_Item__c newItem = new Equipment_Maintenance_Item__c();
                        newItem.Maintenance_Request__c = insertedCase.Id;
                        newItem.Equipment__c = item.Equipment__c;
                        newItem.Quantity__c = item.Quantity__c;
                        itemListToInsert.add(newItem);
                    }
                }
            }
            if (itemListToInsert.size()>0) {
                insert itemListToInsert;
            }
        }
    }

    /** 
     * Helper method to get all maintenance items related to closed requests.
    */
    public static Map<String, List<Equipment_Maintenance_Item__c>> getMaintenanceItems(List<Case> caseList){
        Map<String, List<Equipment_Maintenance_Item__c>> result = new Map<String, List<Equipment_Maintenance_Item__c>>();
        Map<Id, Case> caseKeys = new Map<Id, Case>(caseList);
        List<Equipment_Maintenance_Item__c> itemList = [SELECT  Id, Maintenance_Request__c, Equipment__c, Quantity__c 
                                                        FROM Equipment_Maintenance_Item__c WHERE Maintenance_Request__c 
                                                        IN: caseKeys.keySet()];
        for (Equipment_Maintenance_Item__c item : itemList) {
            if (result.containsKey(item.Maintenance_Request__c)) {
                List<Equipment_Maintenance_Item__c> temp = result.get(item.Maintenance_Request__c);
                temp.add(item);
                result.put(item.Maintenance_Request__c, temp);
            }else {
                result.put(item.Maintenance_Request__c, new List<Equipment_Maintenance_Item__c>{item});
            }
        }
        return result;
    }
}