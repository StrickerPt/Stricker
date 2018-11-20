@isTest
public class Test_Utils {
    testmethod static void test1(){
        Utils.currencySymbol('');
        Utils.getDossTypeName(1);
        Utils.getDossTypeShortName(1);
        Utils.getObjectFieldLabel('Account', 'Name');
    }
    
    testmethod static void test2(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        Product2 prod = [Select Id From Product2 Where RecordType.DeveloperName = 'Produto' Limit 1];
        pricebookEntry pbe = [Select Id, Preco_1__c,Minimo_1__c, Maximo_1__c, Product2Id From PricebookEntry Where Product2Id = :prod.Id Limit 1];
        pbe.Minimo_1__c = 1;
        pbe.Maximo_1__c = 10;
        Preco_por_cliente__c preco = new Preco_por_cliente__c();
        preco.Cliente__c = result.acc.Id;
        preco.Produto__c = prod.Id;
        preco.Valor__c = 5;
        
        insert preco;
        
        Test.startTest();
        
        Utils.calculaPreco(result.acc, pbe, 1, new Map<String, Preco_por_cliente__c>());
        
        Utils.calculaPreco(result.acc, pbe, 1, Utils.getMapaPrecos(result.acc.Numero_de_cliente__c));
        
    }
    
    testmethod static void test3(){
        
        Utils.buildChaveCustomizacao(Utils.buildProduto('81000', '4A', '1', '1', '1', 0, 0));        
        Utils.buildChaveCustomizacao(Utils.buildProduto('81000', '5', '1', '1', '1', 0, 0));
        Utils.buildChaveCustomizacao(Utils.buildProduto('81000', '4A', '1', '1', '1'));    
    }
}