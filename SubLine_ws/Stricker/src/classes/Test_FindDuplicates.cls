@isTest
public class Test_FindDuplicates {
	
    static testmethod void c_FindDuplicates() {
        test.startTest();
        
        Lead newLead = new Lead(FirstName = 'Teste', LastName='Name', Company='Companhia');
        insert newLead;
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(newLead);
        c_FindDuplicates myCtrl = new c_FindDuplicates(ctrl);
        
        String lockFields = myCtrl.getLockedFields();
        
        test.stopTest();
    }
}