@isTest
public class Test_Contact {
    static testmethod void t_Contact() {
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        Contact contact = new Contact();
        contact.LastName = 'Test';
        contact.AccountId = result.acc.Id;
        
        checkRecursive.runContact = true;
        insert contact;
        
        contact.Email = 'test@test.pt';
        checkRecursive.runContact = true;
        update contact;

    }
    static testmethod void t_DelContact() {

        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        Contact contact = new Contact();
        contact.LastName = 'Test';
        contact.AccountId = result.acc.Id;
        
        checkRecursive.runContact = true;
        insert contact;

        checkRecursive.runContact = true;
        delete contact;
    }
    
    @TestSetup
    public static void setup(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
    }
}