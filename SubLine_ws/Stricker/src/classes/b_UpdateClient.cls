global class b_UpdateClient implements Schedulable{
    public Integer pagina {get;set;}    
    
    /**************************************************SCHEDULABLE****************************************************************************/
    global b_UpdateClient(){
        this.pagina = 1;
    }
    
    global b_UpdateClient(Integer pagina){
        this.pagina = pagina;
    }
    
    global void execute(SchedulableContext SC) {
        futureJob(this.pagina);
    }
    
    public static String GetCRONExpression(Datetime dt) {
        return ('' + dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year());
    }
    
    @future(callout=true)
    public static void futureJob(Integer pagina){
        Map<String,ID> users = new Map<String,ID>();
        for(User u :[select Id,Name from User where IsActive = true]){
            users.put(u.Name, u.Id);
        }
                    
        List<clientStricker.ListaClientesAlteradosPHC> resultados = new List<clientStricker.ListaClientesAlteradosPHC>();
        
        Integer maxPagina = 1;
        Integer limitCallout = 1;
        
        do {
            clientStricker.ListaClientesAlteradosPHC resultado = Integrator.servico.lstClientesPHC(pagina);
            
            resultados.add(resultado);
            
            maxPagina = resultado.numtotalPaginas;
            pagina++;
            limitCallout++;
            
        }while(pagina <= maxPagina && limitCallout <= 99);
        
        List<Account> accountsToUpdate = new List<Account>();
        Set<String> addedIds = new Set<String>();
        for(clientStricker.ListaClientesAlteradosPHC r : resultados){
            if(r.listaClientes != null && r.listaClientes.ClienteSalesToPHCBatch != null){
                for(clientStricker.ClienteSalesToPHCBatch client : r.listaClientes.ClienteSalesToPHCBatch){
                    Account acc = new Account();
                    acc.CurrencyIsoCode = client.CurrencyIsoCode != null ? client.CurrencyIsoCode : 'EUR';
                    acc.Numero_de_cliente__c = client.Numero_de_cliente_xc;
                    acc.Bloqueado__c = client.Bloqueado_xc;
                    acc.Inativo__c = client.Inativo_xc;
                    acc.Contencioso__c = client.Contencioso_xc;
                    acc.Divida_vencida__c = CurrencyConverter.convert(client.DividaVencida_xc, 'EUR', acc.CurrencyIsoCode);
                    acc.Encomendas_canceladas__c = client.Encomendas_canceladas_xc;
                    //2018-10-22
                    if(!client.Encomendas_canceladas_xc) acc.Notificacao_novo_cliente__c = true;
                    acc.Vendas_totais_ano_anterior__c = CurrencyConverter.convert(client.Vendas_ano_anterior, 'EUR', acc.CurrencyIsoCode);
                    acc.Vendas_totais_ano_homologo__c = CurrencyConverter.convert(client.Vendas_ano_periodoHomologo, 'EUR', acc.CurrencyIsoCode);
                    acc.Vendas_totais_ano_presente__c = CurrencyConverter.convert(client.Vendas_ano_presente, 'EUR', acc.CurrencyIsoCode);
                    acc.Em_curso__c = CurrencyConverter.convert(client.Encomendas_Curso, 'EUR', acc.CurrencyIsoCode);
                    acc.Notas_PHC__c = client.Notas_xc;
                    acc.Divida_nao_titulada_maturidade__c = client.div_nao_titulada_maturidade;
                    acc.Divida_nao_titulada_saldo__c = CurrencyConverter.convert(client.div_nao_titulada_saldo, 'EUR', acc.CurrencyIsoCode);
                    acc.Divida_titulada_maturidade__c = client.div_titulada_maturidade;
                    acc.Divida_titulada_saldo__c = CurrencyConverter.convert(client.div_titulada_saldo, 'EUR', acc.CurrencyIsoCode);
                    if(!addedIds.contains(acc.Numero_de_cliente__c)) accountsToUpdate.add(acc);
                    addedIds.add(acc.Numero_de_cliente__c);
                }
            }
        }
        
        if(!accountsToUpdate.isEmpty()){
            Database.UpsertResult[] accsResults;
            accsResults = Database.upsert(accountsToUpdate, Account.Numero_de_cliente__c, false);
            
            if(!accsResults.isEmpty()){
                List<Database.UpsertResult> failedResults = new List<Database.UpsertResult>();
                for(Database.UpsertResult dbRes : accsResults){
                    if(!dbRes.isSuccess() || Test.isRunningTest()){
                        failedResults.add(dbRes);
                    }
                }
                
                if(!failedResults.isEmpty()) sendFailureEmail(failedResults);
                
            }
        }
        if(limitCallout >= 99){
            DateTime now  = DateTime.now();
            String nowToString = String.ValueOf(now);
            DateTime nextRunTime = now.addMinutes(1);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            
            
            b_UpdateClient sc = new b_UpdateClient(pagina);
            System.schedule('Reagendamento - b_UpdateClient '+nowToString, cronString, sc);
        }
    }

    public static void sendFailureEmail(List<Database.UpsertResult> failedResults){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Account> accs = [Select id From Account Where Numero_de_cliente__c = '1' Limit 1];
        contact c;
        if(!accs.isEmpty()) c = new Contact(AccountId = accs.get(0).Id, LastName='Dummy contact',Email= 'marco.galvao@stepahead.pt');
        else{
            c = new Contact(AccountId = [Select id From Account Limit 1].Id, LastName='Dummy contact',Email= 'marco.galvao@stepahead.pt');
        }
        checkRecursive.runContact = false;
        insert c;
        
        mail.setTargetObjectId(c.Id);
        mail.saveAsActivity = false;
        mail.setToAddresses(new List<String>{'marco.galvao@stepahead.pt','patricia.veiga@stepahead.pt'});
        
        mail.setSubject('Clientes em Falha');
        String emailBody = '';
        
        for(Database.UpsertResult dbR : failedResults){
            emailBody+=dbR.getErrors() + '\n\n';
        }
        mail.setPlainTextBody(emailBody);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        delete c;
    }
}