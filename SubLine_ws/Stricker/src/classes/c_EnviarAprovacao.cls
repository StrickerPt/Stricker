public class c_EnviarAprovacao {
    
    public List<SelectedDoc> docs {get;set;}
    public String nVersions {get;set;}
    
    public Opportunity opp {get;set;}
    public Set<Id> links;
    public c_EnviarAprovacao(ApexPages.StandardController controller){
        if(!Test.isRunningTest()){
            controller.addFields(new List<String>{'Email_para_envio_de_maquete__c','Outro_email_para_envio_de_maquete__c','AccountId','Referencia_interna__c','Auto_Number__c','N_de_versoes_de_maquete__c'});
            opp = (Opportunity) controller.getrecord();
        }
        else{
            opp = [Select Id, Email_para_envio_de_maquete__c,Outro_email_para_envio_de_maquete__c,AccountId, Referencia_interna__c,Auto_Number__c,
                   N_de_versoes_de_maquete__c
                   From Opportunity 
                   Where Id = :controller.getId()];
        }
        
        links = new Set<Id>(); 
        for(ContentDocumentLink cdl : [Select id, ContentDocumentId from ContentDocumentLink Where LinkedEntityId = :opp.Id and ContentDocument.Title like 'FO%']){
            links.add(cdl.ContentDocumentId);
        }
        
        docs = new List<SelectedDoc>();
        
        //2018-09-24 order by adicionado para que as maquetes mais recentes apareçam em cima
        for(ContentDocument doc :[Select id, Title, CreatedDate From ContentDocument Where Id In :links Order by CreatedDate Desc]){
            SelectedDoc newdoc = new SelectedDoc(false, doc);
            docs.add(newDoc);
        } 
    }
    
    public void updateOpp(){
        Id selected;
        
        for(SelectedDoc doc :docs){
            if(doc.selected){
                selected = doc.doc.Id;
            }
        }
        if(selected != null){
            List<ContentVersion> cv = [SELECT Id,VersionData,Title,FileExtension, VersionNumber FROM ContentVersion where ContentDocumentId = :selected and IsLatest = true];
            if(cv != null && !cv.isEmpty()){
                
                opp.Auxiliar_aprovacao_de_maquete__c = false;
                opp.Estado_da_maquete__c = 'Em aprovação do cliente';
                opp.Enviada_para_cliente__c = true;
                opp.N_de_versoes_de_maquete__c = opp.N_de_versoes_de_maquete__c != null ? opp.N_de_versoes_de_maquete__c + 1 : 1;
                opp.Espera_de_integracao__c = true;
                update opp;
                
                ContentVersion version = cv[0];
                EmailTemplate template = [Select Id from EmailTemplate where Name = 'Aprovação Maquete'];
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(template.Id);
                mail.setOrgWideEmailAddressId([Select id from OrgWideEmailAddress Where DisplayName = 'No reply'].Id);
                Contact auxContact = new Contact(AccountId = opp.AccountId, LastName=opp.Email_para_envio_de_maquete__c,Email=opp.Email_para_envio_de_maquete__c );
                checkRecursive.runContact = false;
                insert auxContact;
                mail.setTargetObjectId(auxContact.Id);
                List<String> emails = new List<String>();
                if(opp.Email_para_envio_de_maquete__c != null){
                    emails.add(opp.Email_para_envio_de_maquete__c);
                }
                if(opp.Outro_email_para_envio_de_maquete__c != null){
                    emails.add(opp.Outro_email_para_envio_de_maquete__c);
                }
                mail.setToAddresses(emails);
                mail.setWhatId(opp.Id);
                mail.setBccSender(false);
                mail.setUseSignature(false);
                mail.setSaveAsActivity(false);
                
                Messaging.EmailFileAttachment attachmentFile = new Messaging.EmailFileAttachment();
                attachmentFile.setFileName(version.Title+'.'+version.FileExtension);
                attachmentFile.setBody(version.VersionData);
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachmentFile });
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                
                delete auxContact;
            }
        }else{
            system.debug('nada selecionado');
        }
    }
    
    public class SelectedDoc{
        public boolean selected {get;set;}
        public ContentDocument doc {get;set;}
        
        public SelectedDoc(boolean selected, ContentDocument doc){
            this.selected = selected;
            this.doc = doc;
        }
    }
}