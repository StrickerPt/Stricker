public class b_AlertasCobrancas implements Database.Batchable<SObject>, Schedulable, Database.Stateful{
    private static final String currentMonth = String.valueOf(system.today().month());
    private static final List<StaticResource> recursos = [Select id,ContentType,Body,Name From StaticResource Where Name Like '%Info_bank%'];
    private static final Set<String> countryCodes = new Set<String>{'PT', 'ES', 'DE', 'IT', 'FR', 'GB', 'PL'};
    private static final Config_alertas_cobranca__mdt config = [Select Aviso_1__c,Aviso_2__c,Aviso_3__c,Aviso_4__c, Valor_Minimo__c From Config_alertas_cobranca__mdt Order by DeveloperName desc Limit 1];
    private static final String emailTest = 'marcoramos@stricker.pt';//marco.galvao@stepahead.pt
    
    private String emailsType1 = '';
    private String emailsType2 = '';
    private String emailsType3 = '';
    private String emailsType4 = '';
    public Set<String> s_no;
    public b_AlertasCobrancas(){
        s_no = new Set<String>();
    }
    public b_AlertasCobrancas(Set<String> s_no){
        this.s_no = s_no;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String auxMonth = '%' + currentMonth + '%';
        if(s_no.isEmpty()){
            return Database.getQueryLocator([Select id, Email__c,Tabela_de_precos__c,Lingua_do_cliente__c,Numero_de_alertas_1__c,Numero_de_alertas_2__c,BillingCountryCode,
                                             Numero_de_alertas_3__c,Numero_de_alertas_4__c,Numero_de_cliente__c,Name,
                                             (Select Id, Data_de_validade__c, CurrencyIsoCode, convertCurrency(Saldo__c), Valor_debito__c , 
                                              Valor_debito_regularizado__c, Numero_de_documento__c
                                              From Conta_corrente__r 
                                              Where Estado__c != 'Pago' 
                                              And Tipo_de_documento__c In (1,5,6,9,16,17,24,25,26) 
                                              And ((Data_de_validade__c <= :system.today().addDays(Integer.valueOf(config.Aviso_1__c))
                                                    And Data_de_validade__c >= :system.today()) Or
                                                   Data_de_validade__c <= :system.today().addDays(Integer.valueOf(config.Aviso_2__c)))
                                             )
                                             From Account 
                                             Where Bloqueado__c = false 
                                             And Meses_sem_cobranca__c excludes(:auxMonth)//EXCLUI MESES QUE CLIENTE NÃO PAGA
                                             And Tipologia_de_facturacao__c != 'Credit - Recibo La Caixa'//EXCLUI TIPOLOGIA LA CAIXA
                                             And Id In (Select Conta__c 
                                                        From Documentos_financeiros__c 
                                                        Where Estado__c != 'Pago' And
                                                        Tipo_de_documento__c In (1,5,6,9,16,17,24,25,26) 
                                                        And ((Data_de_validade__c <= :system.today().addDays(Integer.valueOf(config.Aviso_1__c))
                                                              And Data_de_validade__c >= :system.today()) Or
                                                             Data_de_validade__c <= :system.today().addDays(Integer.valueOf(config.Aviso_2__c)))
                                                       )]);
        }else{
            return Database.getQueryLocator([Select id, Email__c,Tabela_de_precos__c,Lingua_do_cliente__c,Numero_de_alertas_1__c,Numero_de_alertas_2__c,BillingCountryCode,
                                             Numero_de_alertas_3__c,Numero_de_alertas_4__c,Numero_de_cliente__c,Name,
                                             (Select Id, Data_de_validade__c, CurrencyIsoCode, convertCurrency(Saldo__c), Valor_debito__c , 
                                              Valor_debito_regularizado__c, Numero_de_documento__c
                                              From Conta_corrente__r 
                                              Where Estado__c != 'Pago' 
                                              And Tipo_de_documento__c In (1,5,6,9,16,17,24,25,26) 
                                              And ((Data_de_validade__c <= :system.today().addDays(Integer.valueOf(config.Aviso_1__c))
                                                    And Data_de_validade__c >= :system.today()) Or
                                                   Data_de_validade__c <= :system.today().addDays(Integer.valueOf(config.Aviso_2__c)))
                                             )
                                             From Account 
                                             Where Bloqueado__c = false 
                                             And Numero_de_cliente__c in :s_no
                                             And Meses_sem_cobranca__c excludes(:auxMonth)//EXCLUI MESES QUE CLIENTE NÃO PAGA
                                             And Tipologia_de_facturacao__c != 'Credit - Recibo La Caixa'//EXCLUI TIPOLOGIA LA CAIXA
                                             And Id In (Select Conta__c 
                                                        From Documentos_financeiros__c 
                                                        Where Estado__c != 'Pago' And
                                                        Tipo_de_documento__c In (1,5,6,9,16,17,24,25,26) 
                                                        And ((Data_de_validade__c <= :system.today().addDays(Integer.valueOf(config.Aviso_1__c))
                                                              And Data_de_validade__c >= :system.today()) Or
                                                             Data_de_validade__c <= :system.today().addDays(Integer.valueOf(config.Aviso_2__c)))
                                                       )]);
        }
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope){
        Map<Id, Account> accounts = new Map<Id, Account>(scope);//mapa das contas no scope
        Map<Id, Map<Integer, List<Documentos_financeiros__c>>> auxMap = new Map<Id, Map<Integer, List<Documentos_financeiros__c>>>();//Account.Id / Tipo email / docs a enviar
        Map<Id, Contact> dummyContacts = new Map<Id, Contact>();//Account.Id / dummyContact
        Map<Id, Map<Integer,boolean>> hasValue = new Map<Id, Map<Integer,boolean>>();//Account.Id / true if -> sum(docs.Valor_debito__c) >= 100€
        
        /**************************************************ISTO DEVIA DE SER FEITO NA QUERY******************************************************/
        //verificar se tem valor suficiente
        for(Account acc : scope){
            Decimal aux1 = 0; //euros
            Decimal aux2 = 0; //euros
            Decimal aux3 = 0; //euros
            Decimal aux4 = 0; //euros
            hasValue.put(acc.Id, new Map<Integer, boolean>());
            for(Documentos_financeiros__c doc : acc.Conta_corrente__r){
                if(doc.Data_de_validade__c <= System.today().addDays(Integer.valueOf(config.Aviso_3__c)) && doc.Data_de_validade__c >= System.today().addDays(Integer.valueOf(config.Aviso_4__c))){
                    aux3 += doc.Valor_debito__c - doc.Valor_debito_regularizado__c;
                }else if(doc.Data_de_validade__c <= System.today().addDays(Integer.valueOf(config.Aviso_1__c)) && doc.Data_de_validade__c >= System.today()){
                    aux1 += doc.Valor_debito__c - doc.Valor_debito_regularizado__c;
                }else if(doc.Data_de_validade__c <= System.today().addDays(Integer.valueOf(config.Aviso_2__c)) && doc.Data_de_validade__c >= System.today().addDays(Integer.valueOf(config.Aviso_3__c))){
                    aux2 += doc.Valor_debito__c - doc.Valor_debito_regularizado__c;
                }else if(doc.Data_de_validade__c <= System.today().addDays(Integer.valueOf(config.Aviso_4__c))){
                    aux4 += doc.Valor_debito__c - doc.Valor_debito_regularizado__c;
                }
            }

            hasValue.get(acc.Id).put(1, CurrencyConverter.convert(aux1, ProductManager.mapISOCodes.get(acc.Tabela_de_precos__c), 'EUR') >= config.Valor_Minimo__c);
            hasValue.get(acc.Id).put(2, CurrencyConverter.convert(aux2, ProductManager.mapISOCodes.get(acc.Tabela_de_precos__c), 'EUR') >= config.Valor_Minimo__c);
            hasValue.get(acc.Id).put(3, CurrencyConverter.convert(aux3, ProductManager.mapISOCodes.get(acc.Tabela_de_precos__c), 'EUR') >= config.Valor_Minimo__c);
            hasValue.get(acc.Id).put(4, CurrencyConverter.convert(aux4, ProductManager.mapISOCodes.get(acc.Tabela_de_precos__c), 'EUR') >= config.Valor_Minimo__c);
        }
        /*************************************************************************************************************************************/

        for(Account acc : scope){
            for(Documentos_financeiros__c doc : acc.Conta_corrente__r){
                if(!auxMap.containsKey(acc.Id)){
                    auxMap.put(acc.Id, new Map<Integer, List<Documentos_financeiros__c>>());
                }
                if(auxMap.get(acc.Id).containsKey(3)){
                    if(doc.Data_de_validade__c < System.today().addDays(Integer.valueOf(config.Aviso_3__c)) && doc.Data_de_validade__c > System.today().addDays(Integer.valueOf(config.Aviso_4__c))){
                        auxMap.get(acc.Id).get(3).add(doc);
                    }
                }else{
                    integer tipo = 0;
                    if(doc.Data_de_validade__c <= System.today().addDays(Integer.valueOf(config.Aviso_3__c)) && doc.Data_de_validade__c >= System.today().addDays(Integer.valueOf(config.Aviso_4__c))){
                        tipo = 3;
                    }else if(doc.Data_de_validade__c <= System.today().addDays(Integer.valueOf(config.Aviso_1__c)) && doc.Data_de_validade__c >= System.today()){
                        tipo = 1;
                    }else if(doc.Data_de_validade__c <= System.today().addDays(Integer.valueOf(config.Aviso_2__c)) && doc.Data_de_validade__c >= System.today().addDays(Integer.valueOf(config.Aviso_3__c))){
                        tipo = 2;
                    }else if(doc.Data_de_validade__c <= System.today().addDays(Integer.valueOf(config.Aviso_4__c))){
                        tipo = 4;
                    }
                    
                    if(tipo != 0){//se não encontra datas não é para mandar email
                        if(!auxMap.get(acc.Id).containsKey(tipo)) auxMap.get(acc.Id).put(tipo, new List<Documentos_financeiros__c>());
                        auxMap.get(acc.Id).get(tipo).add(doc);
                        dummyContacts.put(acc.Id, new Contact(AccountId = scope.get(0).Id, LastName='Dummy contact',Email = emailTest));//(acc.Email__c != null ? acc.Email__c : 'test@test.com')
                    }
                }
            }
        }
        
        checkRecursive.runContact = false;
        insert dummyContacts.values();
        
        system.debug(auxMap);
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Id key :auxMap.keySet()){
            if(dummyContacts.containsKey(key) && dummyContacts.get(key).Email != '' && !auxMap.get(key).isEmpty()){
                if(auxMap.get(key).keySet().contains(3)){
                    //enviar email 3
                    if(hasValue.get(key).get(3)){
                        emails.add(buildEmail(3, accounts.get(key), dummyContacts.get(key), auxMap.get(key).get(3)));
                        accounts.get(key).Encomendas_canceladas__c = true;
                        accounts.get(key).Numero_de_alertas_3__c = accounts.get(key).Numero_de_alertas_3__c != null ? 
                            accounts.get(key).Numero_de_alertas_3__c + 1 : 1;
                        
                        emailsType3 += buildResumeString(accounts.get(key), auxMap.get(key).get(3));
                    } 
                }else{
                    for(Integer key2 :auxMap.get(key).keySet()){
                        //enviar email 1,2 e 4  
                        if(hasValue.get(key).get(key2)){
                            emails.add(buildEmail(key2, accounts.get(key), dummyContacts.get(key), auxMap.get(key).get(key2)));
                            accounts.get(key).put('Numero_de_alertas_' + key2 + '__c',
                                                  (accounts.get(key).get('Numero_de_alertas_' + key2 + '__c') != null ? 
                                                   (Decimal) accounts.get(key).get('Numero_de_alertas_' + key2 + '__c') + 1 : 1));
                            if(key2 == 4) {
                                accounts.get(key).Data_de_ultimo_alerta_para_juridico__c = System.today();
                                emailsType4 += buildResumeString(accounts.get(key), auxMap.get(key).get(key2));
                            }else if(key2 == 2){
                                emailsType2 += buildResumeString(accounts.get(key), auxMap.get(key).get(key2));
                            }else if(key2 == 1){
                                emailsType1 += buildResumeString(accounts.get(key), auxMap.get(key).get(key2));
                            }
                        }
                    }
                }           
            }
        }
        
        Messaging.sendEmail(emails);
        
        update accounts.values();
        delete dummyContacts.values();
    }

    public Messaging.SingleEmailMessage buildEmail(Integer tipo, Account conta, Contact auxContact, List<Documentos_Financeiros__c> docs){
        Map<Id,Documentos_Financeiros__c> mapDocs = new Map<Id,Documentos_financeiros__c>(docs);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String tempName = 'Alerta_' + tipo;
        system.debug(tipo);
        EmailTemplate template = [Select Id from EmailTemplate where DeveloperName = :tempName];
        mail.setOrgWideEmailAddressId([Select id from OrgWideEmailAddress Where DisplayName = 'No reply'].Id);
        mail.setTemplateId(template.Id);
        mail.setTargetObjectId(auxContact.Id);


        mail.setWhatId(conta.Id);
        
        /* ATE 2018-10-03
        String attach = '';
        if(conta.Tabela_de_precos__c == '3' || conta.Tabela_de_precos__c == '5' || conta.Tabela_de_precos__c == '6'){
            attach = conta.Tabela_de_precos__c;
        }else if(conta.Lingua_do_cliente__c == 'pt_BR' || conta.Lingua_do_cliente__c == 'es' || conta.Lingua_do_cliente__c == 'fr' ){
            attach = conta.Lingua_do_cliente__c;
        }else{
            attach = 'default';
        }*/
        //A PARTIR DE 2018-10-03
        String attach = '';
        if(countryCodes.contains(conta.BillingCountryCode)){
            attach = conta.BillingCountryCode;
        }else //MOEDA USD
            if(ProductManager.mapISOCodes.get(conta.Tabela_de_precos__c) == 'USD'){
            attach = 'USD';
        }else{//RESTO DO MUNDO
            attach = 'INT';
        }
        attach = 'Info_bank_' + attach;
        
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

        for(StaticResource res : recursos){
            if(res.Name == attach){
                Messaging.EmailFileAttachment attachmentFile = new Messaging.EmailFileAttachment();
                attachmentFile.setFileName('Info_bank.'+res.ContentType.split('/')[1]);
                attachmentFile.setBody(res.body);
                attachments.add(attachmentFile);
                break;
            }
        }
        //***************************************************************ISTO TA MAL
        for(Documentos_financeiros__c doc : docs){
            List<ContentDocumentLink> links = [Select id,ContentDocumentId from ContentDocumentLink Where LinkedEntityId = :doc.Id];
            Set<Id> docIds = new set<Id>();
            for(ContentDocumentLink link : links){
                docIds.add(link.ContentDocumentId);
            }
            
            List<ContentVersion> cv = [Select id,FileExtension,VersionData,Title from ContentVersion Where ContentDocumentId IN :docIds And isLatest = true];
            for(ContentVersion version :cv){
                Messaging.EmailFileAttachment attachmentFile = new Messaging.EmailFileAttachment();
                attachmentFile.setFileName(version.Title + '.' + version.FileExtension);
                attachmentFile.setBody(version.VersionData);
                attachments.add(attachmentFile);
            }
        }
        
        /************************************************************ERA ASSIM QUE DEVIA DE SER FEITO
        List<ContentDocumentLink> links = [Select id,ContentDocumentId from ContentDocumentLink Where LinkedEntityId = :account.Id];
       	Set<Id> docIds = new Set<Id>();
        
        for(ContentDocumentLink link : links){
            docIds.add(link.ContentDocumentId);
        }
        
        List<ContentVersion> cv = [Select id,FileExtension,VersionData,Title from ContentVersion Where ContentDocumentId IN :docIds And isLatest = true];
        for(ContentVersion version :cv){
            Messaging.EmailFileAttachment attachmentFile = new Messaging.EmailFileAttachment();
            attachmentFile.setFileName(version.Title + '.' + version.FileExtension);
            attachmentFile.setBody(version.VersionData);
            attachments.add(attachmentFile);
        }*/
        mail.setFileAttachments(attachments);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setSaveAsActivity(false);
        return mail;
    }
    
    public String buildResumeString(Account acc, List<Documentos_Financeiros__c> docs){
        String result = 'Alerta de pagamento para o cliente '+ acc.Numero_de_cliente__c + ': ' + acc.Name +'\n\n';
        
        for(Documentos_financeiros__c doc : docs){
            result += doc.Numero_de_documento__c + ' | Vencimento ' + (doc.Data_de_validade__c != null ? doc.Data_de_validade__c.format(): null) 
                + ' | Limite: ' + (acc.Limite_de_credito_comercial__c != null ? acc.Limite_de_credito_comercial__c : 0)
                + ' | Valor: ' + doc.Valor_debito__c + currencySymbol(doc.CurrencyIsoCode) + '\n';
        }
        result += '\n\n';
        return result;
    }
    
    public void finish(Database.BatchableContext BC){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Account> accs = [Select id From Account Where Numero_de_cliente__c = '1' Limit 1];
        contact c;
        if(!accs.isEmpty()) c = new Contact(AccountId = accs.get(0).Id, LastName='Dummy contact',Email= emailTest);
        else{
            c = new Contact(AccountId = [Select id From Account Limit 1].Id, LastName='Dummy contact',Email= emailTest);
        }
        checkRecursive.runContact = false;
        insert c;
        
        //******************************************TIPO 1
        if(emailsType1 != ''){
            mail.setTargetObjectId(c.Id);
            mail.saveAsActivity = false;
            
            mail.setSubject('Alertas de Pagamento - Pré Aviso');
            mail.setPlainTextBody('Resumo:\n\n' + emailsType1);
            emails.add(mail);
        }
        //******************************************TIPO 2
        if(emailsType2 != ''){
            mail = new Messaging.SingleEmailMessage();
            
            mail.setTargetObjectId(c.Id);
            mail.saveAsActivity = false;
            
            mail.setSubject('Alertas de Pagamento - Mais de 15 dias de atraso');
            mail.setPlainTextBody('Resumo:\n\n' + emailsType2);
            emails.add(mail);
        }
        //******************************************TIPO 3
        if(emailsType3 != ''){
            mail = new Messaging.SingleEmailMessage();
            
            mail.setTargetObjectId(c.Id);
            mail.saveAsActivity = false;
            
            mail.setSubject('Alertas de Pagamento - Cancelamento de encomendas');
            mail.setPlainTextBody('Resumo:\n\n' + emailsType3);
            emails.add(mail);
        }
        //******************************************TIPO 4
        if(emailsType4 != ''){
            mail = new Messaging.SingleEmailMessage();
            
            mail.setTargetObjectId(c.Id);
            mail.saveAsActivity = false;
            
            mail.setSubject('Alertas de Pagamento - Departamento Jurídico');
            mail.setPlainTextBody('Resumo:\n\n' + emailsType4);
            emails.add(mail);
        }
        
        Messaging.sendEmail(emails);
        delete c;
    }
    
    public void execute(System.SchedulableContext SC){
        Database.executeBatch(this, 1);
    }
    
    public static String currencySymbol(String iso) { 
        String symbol = iso;  
        if (iso=='USD') { symbol='$'; } 
        else if (iso=='PLN') { symbol='zl'; }
        else if (iso=='GBP') { symbol='£'; } 
        else if (iso=='EUR') { symbol='€'; }
        return symbol; 
    }
}