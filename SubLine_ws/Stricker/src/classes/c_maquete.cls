public without sharing class c_maquete {
    public Opportunity opp {get;set;}
    public String motivo {get;set;}
    public String versao {get;set;}
    public String docId {get;set;}
    public Boolean isRetificar {get;set;}
    public Boolean isBlocked {get;set;}
    public Boolean isSucess {get;set;}
    public Attachment content {get;set;}
    public Blob dummyBlob {get;set;}
    public List<String> uploadedFiles {get;set;}

    public c_maquete(){
        String idopp = ApexPages.currentPage().getParameters().get('id');
        docId = ApexPages.currentPage().getParameters().get('doc');
        versao = ApexPages.currentPage().getParameters().get('v');
        if(idopp != null){
            this.opp = [select Id,Estado_da_maquete__c,Account.Name, Retificacoes_pedidas_pelo_cliente__c, Versao_de_maquete_enviada__c,
                        Auxiliar_aprovacao_de_maquete__c, Account.Lingua_do_cliente__c from Opportunity where Id = :idopp];
            isBlocked = opp.Estado_da_maquete__c != 'Em aprovação do cliente' || opp.Auxiliar_aprovacao_de_maquete__c;
        }
        isSucess = false;
        uploadedFiles = new List<String>();
        content = new Attachment();
		content.ParentId = opp.Id;
    }
    
    public void retificar(){
        isRetificar = isRetificar != true;
        system.debug(content);
        system.debug(uploadedFiles);
        
    }
    
    public void enviar(){
        Opportunity auxOpp = [Select id, Estado_da_Maquete__c, Auxiliar_aprovacao_de_maquete__c From Opportunity Where id = :opp.Id];
        if(auxOpp.Estado_da_maquete__c == 'Em aprovação do cliente' && !auxOpp.Auxiliar_aprovacao_de_maquete__c){
            opp.Retificacoes_pedidas_pelo_cliente__c = opp.Retificacoes_pedidas_pelo_cliente__c == null ? '' : opp.Retificacoes_pedidas_pelo_cliente__c + '\n';
            opp.Retificacoes_pedidas_pelo_cliente__c += system.today().format() + ': ' + motivo;
            opp.Auxiliar_aprovacao_de_maquete__c = true;
            opp.Espera_de_integracao__c = true;
            List<ContentVersion> newDocs = new List<ContentVersion>();
            
            /*
            for(Attachment att :uploadedFiles){
                ContentVersion contentVersion_1 = new ContentVersion(
                    Title = att.Name,
                    PathOnClient = att.Name,
                    VersionData = att.Body,
                    IsMajorVersion = true
                );
                newDocs.add(contentVersion_1);
            }
			*/
            
            update opp;
            //if(!newDocs.isEmpty()) insert newDocs;
            
            List<ContentDocumentLink> newShares = new List<ContentDocumentLink>();
            for(ContentVersion doc: [Select id, ContentDocumentId From ContentVersion Where Id In:uploadedFiles and IsMajorVersion = true]){
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = doc.ContentDocumentId;
                cdl.LinkedEntityId = opp.Id;
                cdl.ShareType = 'V';
                newShares.add(cdl);
            }
            if(!newShares.isEmpty()){
                insert newShares;
            }
            
            isSucess = true;
        }
    }
    public Pagereference uploadFile(){
        system.debug(content);
        if(content.Body != null){
            //uploadedFiles.add(content);
            
            ContentVersion contentVersion_1 = new ContentVersion(
                    Title = content.Name,
                    PathOnClient = content.Name,
                    VersionData = content.Body,
                    IsMajorVersion = true
                );
            insert contentVersion_1;
            uploadedFiles.add(contentVersion_1.id);
            
            content = new Attachment();
            content.ParentId = opp.Id;
        }
        
        return null;
    }
    public void aprovar(){
        opp.Estado_da_maquete__c = 'Aprovada';
        opp.N_de_versao_de_maquete_aceite__c = opp.Versao_de_maquete_enviada__c;
        
        update opp;

        isSucess = true;
    }
}