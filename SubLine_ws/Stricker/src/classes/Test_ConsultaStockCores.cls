@isTest
public class Test_ConsultaStockCores {

    testmethod static void test1(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController([Select Id From Product2 Where ProductCode = '81000' Limit 1]);
        
        c_ConsultaStockCores myCtrl = new c_ConsultaStockCores(ctrl);
        
    }
}