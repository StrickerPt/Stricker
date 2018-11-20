public class c_NewExpedition {
    
    public Opportunity opp {get;set;}
    public Map<Integer, List<SelectedAddress>> moradas {get;set;}
    public List<SelectedLinha> linhasOpp {get;set;}
    public List<SelectedTransportadora> tranportadoras {get;set;}
    public boolean sucess {get;set;}
    public String transpHelpString {get;set;}
    public String linhasHelpString {get;set;}
    public String moradasHelpString {get;set;}
    public String criaHelpString {get;set;}
    public TranspRec recTransp {get;set;}
    public String aoCuidadoDe {get;set;}
    public boolean isAuthorized {get;set;}
    
    public Morada_de_entrega__c novaMorada{get;set;}
    public boolean existsExp {get;set;}
    public boolean esperaIntegracao {get;set;}
    
    public boolean outraTransp {get;set;}
    public String outraTranspNome {get;set;}
    public String outraTranspValor {get;set;}
    public String lastModifiedInit;
    
    public c_NewExpedition(){}
    public c_NewExpedition(ApexPages.StandardSetController stdCtrl){
        /****************************************************************************************************************/
        moradasHelpString = 'hideSpinner();showModal("modalMoradas");';
        criaHelpString = 'hideSpinner();showModal("modalCriaMorada");';
        linhasHelpString = 'hideSpinner();showModal("modalLinhas");';//removido pela limitação de ter apenas 1 morada em phc
        transpHelpString = 'hideSpinner();showModal("modalTransportadoras");';
        /*****************************************************************************************************************/
        
        recTransp = new TranspRec();
        
        Profile_Id__mdt adminId = [Select Id,Id__c From Profile_Id__mdt Where QualifiedApiName = 'Administrador_do_sistema'];
        
        opp = buildOpp(ApexPages.currentPage().getParameters().get('id'));
        isAuthorized = (opp.Impresso__c || opp.Autorizada__c != null) && UserInfo.getProfileId() != adminId.Id__c;
        
        lastModifiedInit = opp.LastModifiedById;
        moradas = new Map<Integer, List<SelectedAddress>>();
        sucess = true;
        existsExp = (!opp.Expedicoes__r.isEmpty() && opp.RecordType.DeveloperName != 'Orcamento');
        
        esperaIntegracao = opp.Espera_de_integracao__c;
        Integer index = 0;
        for(Morada_de_entrega__c m :  [Select Id, Morada_de_entrega__c, Codigo_postal__c, Pais__c, Localidade__c,Nome_da_empresa__c,Ao_cuidado_de__c
                                       From Morada_de_entrega__c Where Conta__c = :opp.AccountId Limit 1000]){
                                           if(!moradas.containsKey(index)) moradas.put(index, new List<SelectedAddress>());
                                           moradas.get(index).add(new SelectedAddress(false, m));
                                           if(moradas.get(index).size() >= 1000) index++;
                                       }

        linhasOpp = new List<SelectedLinha>();
        //if(!esperaIntegracao && !opp.Erro_comunicacao__c){
            for(OpportunityLineItem oli : [Select Id, ProductCode, Product2.Name, Expedicao__c, Volume__c, Peso__c, Referencia_SKU__c, Quantity,Codigo_de_cor__c 
                                           From OpportunityLineItem 
                                           Where OpportunityId = :opp.Id And Product2.RecordType.DeveloperName = 'Produto' And ProductCode Not In :c_AddProduct.transpCodes]){
            	linhasOpp.add(new SelectedLinha(opp.RecordType.DeveloperName != 'Orcamento', oli));
        	}
        //}
        tranportadoras = new List<SelectedTransportadora>();
        novaMorada = new Morada_de_entrega__c(Conta__c = opp.AccountId);
        outraTransp = false;
        moradaFilter = new Morada_de_entrega__c();
        filteredListDir = new List<Morada_de_entrega__c>();
    }
    
    public void reCheckIntegration(){
        opp = buildOpp(opp.Id);
        linhasOpp = new List<SelectedLinha>();
        lastModifiedInit = opp.LastModifiedById;
        esperaIntegracao = opp.Espera_de_integracao__c;
        //if(!opp.Espera_de_integracao__c && !opp.Erro_comunicacao__c){
            for(OpportunityLineItem oli : [Select Id, ProductCode, Product2.Name, Expedicao__c, Volume__c, Peso__c, Referencia_SKU__c, Quantity,Codigo_de_cor__c 
                                           From OpportunityLineItem 
                                           Where OpportunityId = :opp.Id And Product2.RecordType.DeveloperName = 'Produto' And ProductCode Not In :c_AddProduct.transpCodes]){
                                               system.debug('linha');
            	linhasOpp.add(new SelectedLinha(opp.RecordType.DeveloperName != 'Orcamento', oli));
        	}
        //}
    }
    
    public Opportunity buildOpp(String oppId){
        return [Select Id, AccountId, Name,Account.BillingCountryCode, Account.BillingPostalCode, CurrencyIsoCode, Account.BillingCountry, Account.BillingCity,Referencia_PHC__c,Account.Tipologia_de_facturacao__c,
                Total_de_produtos__c, Amount, Pricebook2Id, Custo_de_transporte_Stricker__c, Account.Portes__c, Localidade_Online__c, Codigo_Postal_Online__c,Erro_comunicacao__c,
                Pais_Online__c, Morada_de_entrega_online__c, Ao_cuidado_de_online__c, Telefone_logistico__c, Nao_calcula_portes_automaticos__c,Impresso__c, Autorizada__c,LastModifiedById,
                (Select id from Expedicoes__r), Incoterm__c, RecordType.DeveloperName, Stamp__c, Espera_de_integracao__c, Account.Morada_principal__c, Versao_enviada__c
                From Opportunity Where id = :oppId];
    }
    
    public void dummyMethod(){
        system.debug(outraTransp);
        system.debug(outraTranspNome);
        system.debug(outraTranspValor);
    }

    public Morada_de_entrega__c selectedAddress {get;set;}
    public void checkMoradas(){
        errorMsg = '';
        try{
            if(moradaFilter.Id != null){
                selectedAddress =  [Select Id, Morada_de_entrega__c, Codigo_postal__c, Pais__c, Localidade__c,Nome_da_empresa__c,Ao_cuidado_de__c
                                    From Morada_de_entrega__c Where Id = :moradaFilter.Id];
                if(opp.RecordType.DeveloperName != 'Orcamento') checkLinhas();
                return;
            }
        }catch(Exception ex){
            
        }
        for(Integer index : moradas.keySet()){
            for(selectedAddress sa : moradas.get(index)){
                
                if(sa.selected){
                    sucess = true;
                    selectedAddress = sa.morada;
                    
                    //ADICIONADO POR HAVER APENAS 1 MORADA PERMITIDA POR DOSSIER DEVIDO A LIMTACOES DE PHC
                    if(opp.RecordType.DeveloperName != 'Orcamento') checkLinhas();
                    //************************************************************************************
                    return;
                } 
            }
        }
        sucess = false;
    }
    
    
    public Morada_de_entrega__c moradaFilter {get;set;}
    public String filterDir {get;set;}
    public List<Morada_de_entrega__c> filteredListDir {get;set;}
    
    
    public void applyFilterDir(){
        filteredListDir.clear();
        
        if(filterDir != null && filterDir != ''){
            String aux = '%' + filterDir + '%';
            String query = 'Select id, Morada_de_entrega__c,Codigo_postal__c,Pais__c,Localidade__c, Name, Nome_da_empresa__c, Telefone_logistico__c, Ao_cuidado_de__c ' +
                'from Morada_de_entrega__c Where (Codigo_postal__c Like \'' + aux +
                '\' OR Morada_de_entrega__c Like \'' + aux + 
                '\' OR Pais__c Like \'' + aux +
                '\' OR Localidade__c Like \'' + aux + 
                '\' OR Nome_da_empresa__c Like \'' + aux +
                '\' OR Telefone_logistico__c Like \'' + aux + 
                '\' OR Ao_cuidado_de__c Like \'' + aux + '\') And Conta__c = \'' + opp.AccountId + '\' Limit 5';
            filteredListDir = Database.query(query);
        }
    }
    
    public void copiaMoradaOnline(){
        novaMorada.Morada_de_entrega__c = opp.Morada_de_entrega_online__c;
        novaMorada.Codigo_postal__c = opp.Codigo_postal_online__c;
        novaMorada.Pais__c = opp.Pais_online__c;
        novaMorada.Localidade__c = opp.Localidade_online__c;
        novaMorada.Ao_cuidado_de__c = opp.Ao_cuidado_de_online__c;
        novaMorada.Telefone_logistico__c = opp.Telefone_logistico__c;
    }
    
    public void criaMorada(){
        try{
            if(novaMorada.Nome_da_empresa__c == null ||
               novaMorada.Morada_de_entrega__c == null ||
               novaMorada.Telefone_logistico__c == null ||
               novaMorada.Codigo_postal__c == null ||
               novaMorada.Localidade__c == null||
               novaMorada.Pais__c == null
              ){
                  sucess = false;
                  ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,'Por favor, preencher todos os campos.'));
              }else{
                  if(novaMorada.Id != null){
                      if(opp.RecordType.DeveloperName != 'Orcamento') checkLinhas();
                      update novaMorada;
                  }else{
                      
                      SelectedAddress newSa = new SelectedAddress(true, novaMorada);
                      selectedAddress = newSa.morada;
                      if(moradas.isEmpty()){
                          moradas.put(0, new List<SelectedAddress>());
                          moradas.get(0).add(newSa);
                      }else{
                          if(moradas.get(moradas.size()-1).size() < 1000){
                              moradas.get(moradas.size()-1).add(newSa);
                          }else{
                              moradas.put(moradas.size(), new List<SelectedAddress>());
                              moradas.get(moradas.size()-1).add(newSa);
                          }
                      }
                      if(opp.RecordType.DeveloperName != 'Orcamento') checkLinhas();
                      insert novaMorada;
                  }
                  sucess = true;
              }
        }catch(Exception ex){
            sucess = false;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,ex.getMessage() + '; Line: ' + ex.getLineNumber()));
        }
    }
    
    public void selectProds(){
        for(SelectedLinha linha : linhasOpp){
            if(linha.linha.Expedicao__c == null)
                linha.selected = true;
        }	
    }
    Decimal peso;
    public String errorMsg {get;set;}
    public void checkLinhas(){
        errorMsg = '';
        List<OpportunityLineItem> selItems = new List<OpportunityLineItem>();
        for(SelectedLinha linha : linhasOpp){
            if(linha.selected){
                selItems.add(linha.linha);
            }
        }
        sucess = !selItems.isEmpty();
        if(sucess){
            Decimal volume = 0;
            peso = 0;
            for(OpportunityLineItem oli : selItems){
                volume += oli.Volume__c != null ? oli.Volume__c : 0;
                peso += oli.Peso__c != null ? oli.Peso__c : 0;
            }
            try{
                String token = w_StrickerService.auth();
                WrapperCalculoTransportadora result = 
                    w_StrickerService.calculaTransporte(
                        token,//token
                        selectedAddress.Pais__c,//paisCliente 
                        selectedAddress.Codigo_postal__c,//codPostalCliente 
                        selectedAddress.Localidade__c,//localidade 
                        String.valueOf(opp.Amount),//total_encomenda 
                        String.valueOf(peso),//peso 
                        String.valueOf(volume),//volume 
                        opp.CurrencyIsoCode,//moeda 
                        opp.Account.BillingCountryCode,//country_iso 
                        opp.Account.BillingPostalCode);//codpostal 
                system.debug(result);
                system.debug(peso);
                tranportadoras.clear();
                for(String field : WrapperCalculoTransportadora.fields){
                    if(result.get(field) != null){
                        WrapperCalculoTransportadora.Dados d = result.get(field);
                        if(recTransp.value == null || recTransp.value > d.valor_transporte) recTransp = new TranspRec(field.replace('_', ' '), d.valor_transporte);
                        system.debug(recTransp);
                        tranportadoras.add(new SelectedTransportadora(false, field.replace('_', ' '), d.valor_transporte, d.valor_despacho, d.valor_custo, d.duracao, d.moeda, d.peso));
                        system.debug(result.get(field));
                    }
                }
                tranportadoras.add(new SelectedTransportadora(false, Label.Recolha_do_cliente, null, null, null, '--', '--', '--'));
                system.debug(tranportadoras);
                w_StrickerService.clearSessions(token);
            }catch(CalloutException ex){
                errorMsg = Label.Problema_de_servico + ' ' + ex.getMessage();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, errorMsg));
                sucess = false;
            }catch(Exception ex){
                errorMsg = ex.getMessage();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, errorMsg));
                sucess = false;
            }
        }
    }
    
    public void checkTransportadoras(){
        if(outraTransp){
            saveExp(new SelectedTransportadora(true, //selected
                                               outraTranspNome, //nome
                                               (outraTranspValor.isNumeric() ?
                                                Double.valueOf(outraTranspValor):
                                                Double.valueOf(0) //valor
                                               ),
                                               Double.valueOf(0),//despacho
                                               Double.valueOf(0),//custo
                                               '0',//duracao
                                               opp.CurrencyIsoCode,//moeda
                                               String.valueOf(peso)));//peso
            return;
        }else{
            for(SelectedTransportadora transp : tranportadoras){
                if(transp.selected){
                    saveExp(transp);
                    return;
                }
            }
        }
        //sendFailureEmail('Erro verificação de transportadora selecionada: Nova Morada = ' + novaMorada + ' Transportadoras = ' + tranportadoras);
        sucess = false;
    }
    
    public void saveExp(SelectedTransportadora transp){
        Expedicao__c exp = new Expedicao__c();
        exp.Dossier__c = opp.Id;
        exp.Morada_de_entrega__c = selectedAddress.Id;
        exp.Transportadora__c = transp.nome;
        exp.Recolha_do_cliente__c = transp.nome == Label.Recolha_do_cliente;
        exp.Ao_cuidado_de__c = selectedAddress.Ao_cuidado_de__c;
        exp.Valor_transporte__c = transp.valor_transporte;
        exp.Valor_despacho__c = transp.Valor_despacho;
        exp.Valor_custo__c = transp.valor_custo;
        exp.Peso_da_expedicao__c = transp.peso != null && transp.peso.isNumeric() ? Decimal.valueOf(transp.peso) : null;
        try{
            Boolean canUpdate = [Select Id, LastModifiedById From Opportunity Where id = :opp.Id].LastModifiedById == lastModifiedInit;
            if(canUpdate){
                insert exp;
                
                update selectedAddress;
                checkRecursive.runFalse();
                Set<Id> allIds = new Map<Id, OpportunityLineItem>([Select Id From OpportunityLineItem Where OpportunityId = :opp.Id]).keySet();
                List<OpportunityLineItem> updateLinhas = new List<OpportunityLineItem>();
                Set<String> refRelac = new Set<String>();
                for(SelectedLinha sl : linhasOpp){
                    if(sl.selected && allIds.contains(sl.linha.Id)){
                        OpportunityLineItem item = sl.linha;
                        
                        item.Expedicao__c = exp.Id;
                        updateLinhas.add(item);
                        
                        refRelac.add(item.Id);//ids para as customizações
                        refRelac.add(item.Stamp__c);
                    }
                }
                
                for(OpportunityLineItem custom : [Select Id From OpportunityLineItem Where Referencia_Relacionada__c In :refRelac And
                                                  Id Not In :refRelac 
                                                  And Product2.RecordType.DeveloperName != 'Produto'
                                                  And Id In :allIds]){
                                                      
                                                      custom.Expedicao__c = exp.Id;
                                                      updateLinhas.add(custom);
                                                  }
                
                update updateLinhas;
                
                /***criar linha de transportadora apenas se não for recolha de cliente
* construir Oli
* ir buscar pricebook entry do produto de transportadora
* inserir oli;
*/
                if(transp.nome != Label.Recolha_do_cliente){
                    OpportunityLineItem linhaTransportadora = new OpportunityLineItem();
                    linhaTransportadora.OpportunityId = opp.Id;
                    linhaTransportadora.Expedicao__c = exp.Id;
                    linhaTransportadora.UnitPrice = (transp.valor_transporte != null ? transp.valor_transporte : 0);
                    linhaTransportadora.Preco_unitario__c = linhaTransportadora.UnitPrice;
                    linhaTransportadora.Quantity = 1;
                    linhaTransportadora.Total_de_customizacao__c = linhaTransportadora.Preco_unitario__c * linhaTransportadora.Quantity;
                    
                    system.debug(LoggingLevel.INFO, opp.Account.Portes__c + '');
                    PricebookEntry pbe = [Select Id, ProductCode
                                          From PricebookEntry 
                                          Where Pricebook2Id = :opp.Pricebook2Id 
                                          And ProductCode = :(opp.Account.Portes__c != null ? opp.Account.Portes__c : 'NSPTER')
                                          And CurrencyIsoCode = :opp.CurrencyIsoCode
                                          And isActive = true Limit 1];
                    linhaTransportadora.PricebookEntryId = pbe.Id;
                    linhaTransportadora.Referencia_SKU__c = pbe.ProductCode;
                    insert linhaTransportadora;
                    exp.Linha_de_transporte__c = linhaTransportadora.Id;
                    //linha despacho
                    
                    if(pbe.ProductCode == 'NSPTER'){
                        OpportunityLineItem linhaDespacho = new OpportunityLineItem();
                        linhaDespacho.OpportunityId = opp.Id;
                        linhaDespacho.Expedicao__c = exp.Id;
                        linhaDespacho.UnitPrice = (transp.valor_despacho != null ? transp.valor_despacho : 0);
                        linhaDespacho.Preco_unitario__c = linhaDespacho.UnitPrice;
                        linhaDespacho.Quantity = 1;
                        linhaDespacho.Total_de_customizacao__c = linhaDespacho.Preco_unitario__c * linhaDespacho.Quantity;
                        PricebookEntry pbeDes = [Select Id,ProductCode
                                                 From PricebookEntry 
                                                 Where Pricebook2Id = :opp.Pricebook2Id 
                                                 And ProductCode = 'NSDESPACHCLI'
                                                 And CurrencyIsoCode = :opp.CurrencyIsoCode And isActive = true Limit 1];
                        linhaDespacho.PricebookEntryId = pbeDes.Id;
                        linhaDespacho.Referencia_SKU__c = pbeDes.ProductCode;
                        
                        insert linhaDespacho;
                        exp.Linha_de_despacho__c = linhaDespacho.Id;
                    }
                    
                    update exp;
                    opp.Custo_de_transporte_Stricker__c = (opp.Custo_de_transporte_Stricker__c != null ? opp.Custo_de_transporte_Stricker__c : 0)
                        +  (transp.valor_custo != null ? transp.valor_custo : 0);
                }
                opp.Incoterm__c = (opp.Incoterm__c == null && exp.Transportadora__c == Label.Recolha_do_cliente) ? 'EXW' : 'DAP';
                if(opp.RecordType.DeveloperName != 'Orcamento' ) opp.Espera_de_integracao__c = true;
                //RP 07-11-2018 incrementacao versao enviada
                if(opp.RecordType.DeveloperName != 'Orcamento' && opp.Stamp__c != null){
                    if(opp.Versao_enviada__c != null){
                        opp.Versao_enviada__c = opp.Versao_enviada__c + 1;
                    }else{
                        opp.Versao_enviada__c = 1;
                    }
                }
                update opp;
                if(opp.RecordType.DeveloperName != 'Orcamento' ){
                    if(opp.Stamp__c == null)Integrator.criaDossier(opp.Id);
                    else Integrator.actDossier(new Set<Id> {opp.Id});
                }
                sucess = true;
            }else{
                sucess = false;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, Label.Dossier_manipulado));
            }
        }catch(Exception ex){
            sucess = false;
            try{
                if(exp.Id != null){
                    delete exp;
                }
            }catch(Exception ex2){}
            System.debug(LoggingLevel.INFO, ex.getMessage() + ex.getLineNumber());
            sendFailureEmail(ex.getMessage() + ' ;Linha: ' + ex.getLineNumber());
        }
    }
    
    public void sendFailureEmail(String message){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String user = UserInfo.getName();
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
        
        mail.setSubject('Falha transportadoras');
        String emailBody = 'User: ' + user + '; Opp: ' + opp.Id + ';\n\n' + message;

        mail.setPlainTextBody(emailBody);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        delete c;
    }
    /*********************************************************ESTRUTURAS*******************************************************/
    public class SelectedAddress{
        public Boolean selected {get;set;}
        public Morada_de_entrega__c morada {get;set;}
        
        public SelectedAddress(Boolean selected, Morada_de_entrega__c morada){
            this.selected = selected;
            this.morada = morada;
        }
    }
    
    public class SelectedLinha{
        public Boolean selected {get;set;}
        public OpportunityLineItem linha {get;set;}
        
        public SelectedLinha(Boolean selected, OpportunityLineItem linha){
            this.selected = selected;
            this.linha = linha;
        }
    }
    
    public class SelectedTransportadora{
        public Boolean selected {get;set;}
        public String nome {get;set;}
        public double valor_transporte {get;set;}
        public double valor_despacho {get;set;}
        public double valor_custo {get;set;}
        public String duracao {get;set;}
        public String moeda {get;set;}
        public String peso {get;set;}
        
        public SelectedTransportadora(Boolean selected, String nome, double valor_transporte, double valor_despacho, double valor_custo, String duracao, String moeda, String peso){
            this.selected = selected;
            this.nome = nome;
            this.valor_transporte = valor_transporte;
            this.valor_despacho = valor_despacho;
            this.valor_custo = valor_custo;
            this.duracao = duracao;
            this.moeda = moeda;
            this.peso = peso;
        }
    }
    
    public class TranspRec{
        public String transp {get;set;}
        public Decimal value {get;set;}
        
        public TranspRec(){}
        
        public TranspRec(String transp, Decimal value){
            this.transp = transp;
            this.value = value;
        }
    }
}