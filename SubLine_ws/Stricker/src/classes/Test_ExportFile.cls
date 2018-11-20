@isTest
public class Test_ExportFile {
    static testmethod void t_ExportFile() {
        test.startTest();
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'FO',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        try{
            
        }catch(Exception ex){
            
        }
        insert contentVersion_1;
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = result.opp.Id;
        contentlink.ContentDocumentId = [select ContentDocumentId from ContentVersion where Id =: contentVersion_1.Id].ContentDocumentId;
        contentlink.ShareType = 'V';
        insert contentlink;
        
        result.opp.StageName = 'Em produção';
        update result.opp;
        
        sh_ExportFile expJob = new sh_ExportFile(new List<String>{result.opp.Id});
        sh_ExportFile.exportJob(new List<String>{result.opp.Id});
        
        Opportunity opp = [Select id, CreatedDate From Opportunity Where Id = :result.opp.Id];
        
        sh_ExportFile.Request request = new sh_ExportFile.Request();
        request.codigoDossier = 'FO';
        request.apiCodigo = '32';
        request.ano = String.valueOf(opp.CreatedDate.year());
        request.fileBase64 = EncodingUtil.base64Encode(contentVersion_1.VersionData);
        request.ext = contentVersion_1.FileExtension;
        request.contentSize = contentVersion_1.ContentSize;
        
        sh_ExportFile expJob2 = new sh_ExportFile(new List<sh_ExportFile.Request>{request});
        
        expJob2.execute(null);
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        try{
            delete documents;
        }catch(Exception e){
            
        }
        
        test.stopTest();
    }
}