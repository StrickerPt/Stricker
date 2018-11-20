public class c_UploadGuia {
    public boolean success {get;set;}
    public Opportunity opp;
    public c_UploadGuia(ApexPages.StandardController controller){
        success = false;
        opp = [Select Id From Opportunity Where Id = :controller.getId()];
    }
    
    public String blobFile {get;set;}
    public String fileName {get;set;}
    public boolean fileSucess {get;set;} 
    public void showBlob(){
        fileSucess = false;
        if(blobFile != null){
            blobFile= blobFile.substring(blobFile.indexOf(',')+1);
            system.debug(blobFile);
            system.debug(fileName);
            
            ContentVersion version = new ContentVersion();
            
            version.VersionData = EncodingUtil.base64Decode(blobFile);
            version.Title = 'Guia_' + fileName;
            if(version.PathOnClient == null) version.PathOnClient = 'Guia_' + fileName;
            if(!Test.isRunningTest()) insert version;
            
            Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>([Select Id, ContentDocumentId From ContentVersion Where Id =:version.Id]);
            
            ContentDocumentLink newLink = new ContentDocumentLink();
            if(!Test.isRunningTest())newLink.ContentDocumentId = versionMap.get(version.Id).ContentDocumentId;
            newLink.LinkedEntityId = opp.Id;
            newLink.ShareType = 'I';
            
            if(!Test.isRunningTest()) insert newLink;
            
            fileSucess = true;
            //fileName = null;
            blobFile = null;
        }
    }
    
}