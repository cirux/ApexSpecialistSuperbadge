/**
 * Synchronize Salesforce data with an external system
 * makes a callout to the external service used for warehouse inventory management. 
 * This service receives updated values in the external system and updates the related records in Salesforce.
 * With this integration, the inventory in Salesforce updates after the equipment is taken from the warehouse to service a vehicle.
 * The callout’s JSON response returns the equipment records that you upsert in Salesforce. 
 */
public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {

    String endpoint = 'https://th-superbadge-apex.herokuapp.com/equipment?_ga=2.116156294.1244765571.1679906796-629538370.1671011827';
    public WarehouseCalloutService() {

    }

    public void execute(QueueableContext qc){
        Http http = new Http();
        // The callout’s JSON response returns the equipment records that you upsert in Salesforce
        List<Product2> equipments = new List<Product2>();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        System.debug('Calling endpoint: ' + endpoint);
        HttpResponse response = http.send(request);
        // If the request is successful, parse the JSON response.
        if(response.getStatusCode() == 200) {
            System.debug('Response received');
            List<ExternalEquipmentDtoList> externalProducts = ExternalEquipmentDtoList.parse(response.getBody());
            System.debug('Response parsed: ' + externalProducts);
            for(ExternalEquipmentDtoList externalProduct : externalProducts){
                // Use the warehouse SKU as the external ID to identify which equipment records to update within Salesforce.
                Product2 product2 = new Product2(
                    Replacement_Part__c = true,
                    ExternalId = externalProduct.sku,
                    Name = externalProduct.name,
                    Maintenance_Cycle__c = externalProduct.maintenanceperiod,
                    Lifespan_Months__c = externalProduct.lifespan,
                    Cost__c = externalProduct.cost,
                    StockKeepingUnit = externalProduct.sku);

                    equipments.add(product2);
            }

            if(equipments.size() > 0){
                System.debug('Upserting ' + equipments.size() + ' products');
                upsert equipments;
            }
        }

    }
}