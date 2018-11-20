@isTest
public class Test_PrecoPorCliente{
    testmethod static void test1(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        Test.startTest();
        
        Preco_por_cliente__c ppc = new Preco_por_cliente__c();
        ppc.Cliente__c = result.acc.Id;
        ppc.Produto__c = [Select Id From Product2 Limit 1].Id;
        ppc.Data_de_inicio__c = System.today();
        ppc.Data_de_fim__c = System.today().addDays(5);
        ppc.Valor__c = 5;
        
        insert ppc;
        try{
            Preco_por_cliente__c ppc2 = new Preco_por_cliente__c();
            ppc2.Cliente__c = result.acc.Id;
            ppc2.Produto__c = [Select Id From Product2 Limit 1].Id;
            ppc2.Data_de_inicio__c = System.today();
            ppc2.Data_de_fim__c = System.today().addDays(5);
            ppc2.Valor__c = 5;
            
            insert ppc2;
        }catch(Exception ex){}
        Test.stopTest();
    }
    
    testmethod static void test2(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        Test.startTest();
        
        Preco_por_cliente__c ppc = new Preco_por_cliente__c();
        ppc.Cliente__c = result.acc.Id;
        ppc.Produto__c = [Select Id From Product2 Limit 1].Id;
        ppc.Data_de_inicio__c = System.today();
        ppc.Data_de_fim__c = System.today().addDays(5);
        ppc.Valor__c = 5;
        
        insert ppc;
        
        delete ppc;
        
        Test.stopTest();
    }
}