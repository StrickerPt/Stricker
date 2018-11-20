@isTest
public class Test_CustomManager {
    @isTest static void testUpdateDossier() {
        TestUtilities.customSettings();
        
        Pricebook2 customPB = new Pricebook2(Name='Mercado 1', isActive=true, Mercado__c = '1');
        insert customPB;
        
        sh_CustomManager newSh = new sh_CustomManager();
        sh_CustomManager newSh2 = new sh_CustomManager(1, 1, Datetime.now().addDays(-1).format('yyyy-MM-dd'));
        
        newSh.execute(null);
    }
}