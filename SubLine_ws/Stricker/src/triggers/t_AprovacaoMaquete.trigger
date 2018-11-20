trigger t_AprovacaoMaquete on Opportunity (before update, after update) {
    if(Trigger.isbefore){
        for(Opportunity opp :trigger.new){
            if(opp.Estado_da_maquete__c == 'Em aprovação do cliente' && trigger.OldMap.get(opp.Id).Estado_da_maquete__c != 'Em aprovação do cliente' && opp.Email_para_envio_de_maquete__c != null){
                List<ContentDocumentLink> cdl = [SELECT ContentDocument.Id FROM ContentDocumentLink WHERE ContentDocument.title like 'FO%' AND LinkedEntityId = :opp.Id];
                if(cdl != null && !cdl.isEmpty()){
                    List<ContentVersion> cv = [SELECT Id,VersionData,Title,FileExtension, VersionNumber FROM ContentVersion where ContentDocumentId =:cdl[0].ContentDocument.Id and IsLatest = true];
                    if(cv != null && !cv.isEmpty()){
                        opp.Versao_de_maquete_enviada__c = integer.valueOf(cv[0].VersionNumber);
                        opp.Auxiliar_aprovacao_de_maquete__c = false;
                    }
                }
            }
            
        }
    }else if(trigger.new.size() == 1){
        for(Opportunity opp :trigger.new){
            if(opp.Estado_da_maquete__c == 'Em aprovação do cliente' && trigger.OldMap.get(opp.Id).Estado_da_maquete__c != 'Em aprovação do cliente' && opp.Email_para_envio_de_maquete__c != null){
                
                List<ContentDocumentLink> cdl = [SELECT ContentDocument.Id FROM ContentDocumentLink WHERE ContentDocument.title like 'FO%' AND LinkedEntityId = :opp.Id];
                if(cdl != null && !cdl.isEmpty()){
                    List<ContentVersion> cv = [SELECT Id,VersionData,Title,FileExtension, VersionNumber FROM ContentVersion where ContentDocumentId =:cdl[0].ContentDocument.Id and IsLatest = true];
                    //List<ContentVersion> cv = [SELECT Id,VersionData,Title,FileExtension, VersionNumber FROM ContentVersion where Title like 'FO%' And ContentDocumentId In :docIds];
                    if(cv != null && !cv.isEmpty()){
                        EmailTemplate template = [Select Id from EmailTemplate where Name = 'Aprovação Maquete'];
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTemplateId(template.Id);
                        mail.setOrgWideEmailAddressId([Select id from OrgWideEmailAddress Where DisplayName = 'No reply'].Id);
                        Contact auxContact = new Contact(AccountId = opp.AccountId, LastName=opp.Email_para_envio_de_maquete__c,Email=opp.Email_para_envio_de_maquete__c );
                        //Contact auxContact2 = new Contact(LastName=opp.Outro_email_para_envio_de_maquete__c,Email=opp.Outro_email_para_envio_de_maquete__c);
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
                        //mail.setSenderDisplayName('');
                        mail.setSaveAsActivity(true);
                        
                        
                        //percorrer lista e enviar varios anexos
                        /*List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                        for(ContentVersion file : cv){
                            Messaging.EmailFileAttachment attachmentFile = new Messaging.EmailFileAttachment();
                            attachmentFile.setFileName(file.Title + '-' + Label.Versao_da_maquete + ' ' + file.VersionNumber +'.'+file.FileExtension);
                            attachmentFile.setBody(file.VersionData);
                            attachments.add(attachmentFile);
                        }
                        mail.setFileAttachments(attachments);*/
                        
                        Messaging.EmailFileAttachment attachmentFile = new Messaging.EmailFileAttachment();
                        attachmentFile.setFileName(cv[0].Title+'.'+cv[0].FileExtension);
                        attachmentFile.setBody(cv[0].VersionData);
                        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachmentFile });
                        
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                        
                        delete auxContact;
                    }
                }
            }
        }
    }
}