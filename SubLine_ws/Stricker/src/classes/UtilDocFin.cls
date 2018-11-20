public class UtilDocFin {
    
    public static void treatDocs(List<clientStricker.ListaDocsFinanceirosPHC> results){
        Map<String, Documentos_financeiros__c> listDocs = new Map<String, Documentos_financeiros__c>();
        Set<String> nClientes = new Set<String>();
        for(clientStricker.ListaDocsFinanceirosPHC res : results){
            if(res.listaDocsFinanceiros != null && res.listaDocsFinanceiros.DocFinanceiroToSales != null){
                for(clientStricker.DocFinanceiroToSales doc : res.listaDocsFinanceiros.DocFinanceiroToSales){
                    /* criar Documento_Financeiro__c
                    * criar conta com external id
                    * Documento_Financeiro__c doc = new Documento_Financeiro__c(....);
                    * doc.Conta__r = new Account(Numero_de_cliente__c = 'External Id');
                    * upsert doc;
                    */
                    Account accAux = new Account(Numero_de_cliente__c = String.valueOf(doc.Numero_de_cliente_xc));
                    nClientes.add(String.valueOf(doc.Numero_de_cliente_xc));
                    if(!listDocs.containsKey(doc.Ftstamp_xc) && accAux != null){
                        Documentos_financeiros__c docFin = new Documentos_financeiros__c();
                        docFin.Conta__r = accAux;
                        docFin.Credito__c = doc.Credito_xc;
                        docFin.Valor_credito_emitido_moeda__c = doc.Valor_credito_emitido_moeda_xc;
                        docFin.Valor_credito_emitido_moeda_regularizado__c = doc.Valor_credito_emitido_moeda_regularizado_xc;
                        docFin.Valor_credito_emitido_euros__c = doc.Valor_credito_emitido_euros_xc;
                        docFin.Valor_debito_emitido_euros__c = doc.Valor_debito_emitido_euros_xc;
                        docFin.Valor_debito_emitido_moeda__c = doc.Valor_debito_emitido_moeda_xc;
                        docFin.Valor_debito_emitido_moeda_regularizado__c = doc.Valor_debito_emitido_moeda_regularizado_xc;
                        docFin.Valor_debito_emitido_euros_regularizado__c = doc.Valor_debito_emitido_euros_regularizado_xc;
                        //docFin.Name = doc.Name;
                        docFin.Ftstamp__c = doc.Ftstamp_xc;
                        docFin.CurrencyIsoCode = doc.Euro_xc == 'PTE ou EURO' ? 'EUR' : doc.Euro_xc;
                        docFin.Valor_credito_emitido_euros_regularizado__c = doc.Valor_credito_emitido_euros_regularizado_xc;
                        docFin.Data__c = doc.DataEmissao != null ? doc.DataEmissao.date() : null;
                        docFin.Data_de_Validade__c = doc.DataValidade != null ? doc.DataValidade.date() : null;
                        docFin.Numero_de_documento__c = doc.numeroDocumento;
                        docFin.Tipo_de_documento__c = doc.nDoc;
                        
                        listDocs.put(doc.Ftstamp_xc, docFin);
                    }
                }
            }
        }
        
        //procurar clientes já existentes
        Map<String, Id> accMap = new Map<String, Id>();
        
        for(Account acc : [Select Id, Numero_de_cliente__c From Account Where Numero_de_cliente__c In :nClientes]){
            accMap.put(acc.Numero_de_cliente__c, acc.Id);
        }
        
        //criar/actualizar documentos financeiros
        Database.UpsertResult[] docsResults;
        if(!listDocs.isEmpty()){
            docsResults = Database.upsert(listDocs.values(), Documentos_financeiros__c.Ftstamp__c, false);
        }
        
        //validar erros de docs
        if(!docsResults.isEmpty()){
            List<Database.UpsertResult> failedResults = new List<Database.UpsertResult>();
            for(Database.UpsertResult dbRes : docsResults){
                if(!dbRes.isSuccess() || Test.isRunningTest()){
                    failedResults.add(dbRes);
                }
            }
            
            String emailBody = '';
            
            for(Database.UpsertResult dbR : failedResults){
                emailBody+=dbR.getErrors() + '\n\n';
            }
            if(!failedResults.isEmpty()) UtilClaims.sendEmailFailure('Documentos Financeiros Falhados', emailBody);
            
        }
        
        //criar ficheiros/ligações
        List<ContentVersion> newVersions = new List<ContentVersion>();
        List<GroupVersionLink> shareLinks = new List<GroupVersionLink>();
        
        for(clientStricker.ListaDocsFinanceirosPHC res : results){
            if(res.listaDocsFinanceiros != null && res.listaDocsFinanceiros.DocFinanceiroToSales != null){
                for(clientStricker.DocFinanceiroToSales doc : res.listaDocsFinanceiros.DocFinanceiroToSales){
                    if(accMap.containsKey(String.valueOf(doc.Numero_de_cliente_xc)) && listDocs.get(doc.Ftstamp_xc).Id != null){
                        ContentVersion version = new ContentVersion();
                        if(doc.docStamp != null && doc.docStamp.trim() != ''){
                            version.VersionData = EncodingUtil.base64Decode(doc.ficheiro);
                            version.DocStamp__c = doc.docStamp;
                            version.Title = doc.numeroDocumento +'.pdf';
                            if(version.PathOnClient == null) version.PathOnClient = doc.numeroDocumento + '.pdf';
                            newVersions.add(version);
                            shareLinks.add(new GroupVersionLink(doc.Ftstamp_xc, version));
                        }
                        
                    }
                }
            }
        }
        
        system.debug(accMap);
        if(!newVersions.isEmpty()){
            Database.UpsertResult[] results2 = Database.upsert(newVersions, ContentVersion.DocStamp__c, false);
        }
        Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>([Select Id, ContentDocumentId From ContentVersion Where Id In :newVersions]);
        
        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        //map<Id, Id> auxMap = new Map<Id, Id>();//ContentVersionId/ContentDocumentID
        for(GroupVersionLink gvl : shareLinks){
            ContentDocumentLink newLink = new ContentDocumentLink();
            if(versionMap.containsKey(gvl.version.Id)){
                newLink.ContentDocumentId = versionMap.get(gvl.version.Id).ContentDocumentId;
                newLink.LinkedEntityId = listDocs.get(gvl.ftstamp).Id;
                newLink.ShareType = 'I';
                newLinks.add(newLink);
                
                newLink = new ContentDocumentLink();
                
                newLink.ContentDocumentId = versionMap.get(gvl.version.Id).ContentDocumentId;
                newLink.LinkedEntityId = accMap.get(listDocs.get(gvl.ftstamp).Conta__r.Numero_de_cliente__c);
                newLink.ShareType = 'I';
                newLinks.add(newLink);
            }
        }
        
        if(!newLinks.isEmpty()) upsert newLinks;
        
    }
    
    public class GroupVersionLink{
        public String ftstamp;
        public ContentVersion version;
        
        public GroupVersionLink(String ftstamp, ContentVersion version){
            this.ftstamp = ftstamp;
            this.version = version;
        }
    }
}