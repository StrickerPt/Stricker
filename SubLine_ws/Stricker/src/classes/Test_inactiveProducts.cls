@isTest
public class Test_inactiveProducts {
    @isTest static void testinactiveProducts() {
        Test.startTest();
        
        TestUtilities.customSettings();
        TestUtilities.createProds();

        //Database.executeBatch(new sh_inactiveProducts());
        sh_inactiveProducts sh1 = new sh_inactiveProducts();
        
        String sch = '0 0 23 * * ?'; system.schedule('Test sh_inactiveProducts', sch, sh1);
        test.stopTest();
    }
}