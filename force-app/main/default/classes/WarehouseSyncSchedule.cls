global with sharing class WarehouseSyncSchedule implements Schedulable {
    // implement scheduled code here
    global void execute(SchedulableContext sc){
        System.debug('WarehouseSyncSchedule');
        ID jobID = System.enqueueJob(new WarehouseCalloutService());
        System.debug('Enqueued job id: ' + jobID);
    }
}