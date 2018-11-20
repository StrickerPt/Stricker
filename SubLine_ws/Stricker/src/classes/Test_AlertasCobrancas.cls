@isTest
public class Test_AlertasCobrancas {

    testmethod static void test1(){
        b_AlertasCobrancas b = new b_AlertasCobrancas();
        
        b.execute(null);

    }
    
    testmethod static void test2(){

        
        Set<String> s_no = new Set<String>();
        for(Account acc: [Select Id, Numero_de_cliente__c From Account]){
            s_no.add(acc.Numero_de_cliente__c);
        }
        b_AlertasCobrancas b1 = new b_AlertasCobrancas(s_no);
        
        b1.execute(null);
    }
    
    @TestSetup
    public static void setup(){
        TestUtilities.customSettings();
        
        Account acc = new Account();
        acc.Name = 'Account Test';
        acc.Bloqueado__c = false;
        acc.Meses_sem_cobranca__c =String.valueOf(System.today().addMonths(1).month());
        acc.Numero_de_cliente__c = '5159';
        insert acc;
        
        Documentos_financeiros__c doc = new Documentos_financeiros__c();
        doc.Conta__c = acc.Id;
        doc.Tipo_de_documento__c = 1;
        doc.Data_de_validade__c = System.today().addDays(1);
        doc.Valor_debito_emitido_euros__c = 250;
        insert doc;
    }
}