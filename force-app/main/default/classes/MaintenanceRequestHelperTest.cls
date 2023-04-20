@IsTest
public with sharing class MaintenanceRequestHelperTest {
    
    @IsTest
    private static void testCaseUpdate(){
        // setup
        Vehicle__c v = new Vehicle__c(Name = 'Vehicle');
        insert v;
        Product2 p = new Product2(Name = 'Product name', Maintenance_Cycle__c = 10, Replacement_Part__c = true);
        insert p;

        Product2 pr = new Product2(Name = 'Product replacement name', Maintenance_Cycle__c = 10, Replacement_Part__c = true);
        insert pr;
        
        List<Case> repairCases = new List<Case>();
        for(Integer i=0; i<15; i++){
            repairCases.add(new Case(
                Vehicle__c = v.Id,
                Product__c = p.Id,
                Type = 'Repair',
                Subject = 'Repair ' + i,
                Date_Reported__c = System.today().addDays(-10),
                Date_Due__c = System.today()));
        }
        insert repairCases;

        List<Case> routineCases = new List<Case>();
        for(Integer i=0; i<15; i++){
            repairCases.add(new Case(
                Vehicle__c = v.Id,
                Product__c = p.Id,
                Type = 'Routine Maintenance',
                Subject = 'Routine Maintenance ' + i,
                Date_Reported__c = System.today().addDays(-10),
                Date_Due__c = System.today()));
        }
        insert routineCases;

        List<Case> toUpdate = [Select Id, Status FROM Case];

        List<Equipment_Maintenance_Item__c> emis = new List<Equipment_Maintenance_Item__c>();
        for(Case c : toUpdate){
            Equipment_Maintenance_Item__c emi = new Equipment_Maintenance_Item__c(
                Maintenance_Request__c = c.Id,
                Equipment__c = pr.Id);
            emis.add(emi);

            Equipment_Maintenance_Item__c emi2 = new Equipment_Maintenance_Item__c(
                Maintenance_Request__c = c.Id,
                Equipment__c = p.Id);
            emis.add(emi2);

            c.Status = 'Closed';
        }
        insert emis;

        // test
              
        Test.startTest();
        update toUpdate;
        Test.stopTest();

        // check
        Date today = System.today();
        List<Case> newRequests = [SELECT Id FROM Case WHERE Date_Reported__c = :today AND Subject = 'Routine checkup'];
        System.assertEquals(false, newRequests.isEmpty());
    }
}