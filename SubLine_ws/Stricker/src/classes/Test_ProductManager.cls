@isTest
public class Test_ProductManager {
    
    @isTest static void testProductManager() {
        Test.startTest();
        
        TestUtilities.customSettings();
        
        Pricebook2 customPB = new Pricebook2(Name='Mercado 1', isActive=true, Mercado__c = '5');
        insert customPB;
        
        //ProductManager.init(1);
        
        test.stopTest();
    }
    
     @isTest static void testShProductManager() {
     	Test.startTest();
        
        TestUtilities.customSettings();
         
        Pricebook2 customPB = new Pricebook2(Name='Mercado 1', isActive=true, Mercado__c = '5');
        insert customPB;
        
        sh_ProductManager manager = new sh_ProductManager();
        
        DateTime now  = DateTime.now();
        String nowToString = String.ValueOf(now);
        DateTime nextRunTime = now.addMinutes(2);
        String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
        
        
        sh_ProductManager sc = new sh_ProductManager(1, 1, Datetime.now().addDays(-1).format('yyyy-MM-dd'));
        System.schedule('Reagendamento - sh_ProductManager '+nowToString, cronString, manager);
        
        test.stopTest();    
     }
}