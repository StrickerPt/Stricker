@isTest
public class Test_EnviarAprovacao {
    static testmethod void test1() {
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        result.opp.Pricebook2Id = Test.getStandardPricebookId();
        update result.opp;

        ContentVersion contentVersion_1 = new ContentVersion();
        contentVersion_1.Title = 'FO';
        contentVersion_1.PathOnClient = 'Penguins.jpg';
        contentVersion_1.VersionData = Blob.valueOf('Test Content');
        contentVersion_1.IsMajorVersion = true;
        insert contentVersion_1;
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = result.opp.Id;
        contentlink.ContentDocumentId = [select ContentDocumentId from ContentVersion where Id =: contentVersion_1.Id].ContentDocumentId;
        contentlink.ShareType = 'V';
        insert contentlink;
        
        Test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_EnviarAprovacao myCtrl = new c_EnviarAprovacao(ctrl);
        myCtrl.docs.get(0).selected = true;
        myCtrl.updateOpp();
        
        Test.stopTest();
    }
}