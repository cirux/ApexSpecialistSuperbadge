/**
 * When an existing maintenance request of type Repair or Routine Maintenance is closed, 
 * create a new maintenance request for a future routine checkup
 */
trigger MaintenanceRequest on Case (after update) {

    if(Trigger.isUpdate){
        System.debug('MaintenanceRequest Trigger UPDATE');
        if(Trigger.isAfter){
            MaintenanceRequestHelper.createMaintenanceRequest(Trigger.newMap);
        }
    }

}