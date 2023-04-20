/**
 * Test callout logic
 */
@IsTest
private class WarehouseCalloutServiceTest {
    // implement your mock callout test here

    @IsTest
    static void testGetCallout(){
        
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());

        // Call method to test
        Test.startTest();
        System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();

        // Verify product insertion
        List<Product2> equipments = [SELECT ID, Warehouse_SKU__c, Maintenance_Cycle__c FROM Product2];
        System.assertNotEquals(null,equipments, 'No product inserted.');
        // Verify status code
        System.assertEquals(2,equipments.size(), 'Wrong number of product inserted.');
    }

}