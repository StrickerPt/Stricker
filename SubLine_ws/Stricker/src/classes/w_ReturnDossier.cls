global class w_ReturnDossier {
    
    static webservice DossierReturn updateDossier(DossierRetorno dossier){
        try{
            system.debug(dossier);
            if(dossier.sf_id != null){
                
                checkRecursive.runOpportunityAfterUpdate = false;
                Map<Id, OpportunityLineItem> newOlis = new Map<Id, OpportunityLineItem>();
                Map<Id, OpportunityLineItem> listOli = new Map<Id,OpportunityLineItem>();
                Map<Id, List<OpportunityLineItem>> auxIds = new Map<Id, List<OpportunityLineItem>>();
                
                Datetime nullDate = Datetime.newInstance(2000, 1, 1);
                Datetime errorDate = Datetime.newInstance(1, 1, 1);
                boolean doBreak = false;
                
                Opportunity opp = Integrator.getOpp(dossier.sf_id);
                Map<String,OpportunityLineItem> linhasExistentes = new Map<String, OpportunityLineItem>(opp.OpportunityLineItems);
                for(OpportunityLineItem oli : linhasExistentes.values()){
                    oli.Alocacao_de_Stock__c = '';
                    oli.Quantity = 0;
                    oli.Peso__c = 0;
                    oli.Volume__c = 0;
                    oli.Total_de_customizacao__c = 0;
                }
                system.debug(LoggingLevel.INFO, 'Validar se trata resposta');
                String autorizada = opp.Autorizada__c;
                if((autorizada == '' || autorizada == null) || (userInfo.getProfileId() == [Select Id__c from Profile_Id__mdt Where DeveloperName = 'Administrador_do_sistema'].Id__c)) {
                    system.debug(LoggingLevel.INFO, 'A tratar resposta');
                    
                    //***************************************************TRATAMENTO DA RESPOSTA*************************************************
                    Map<Id, Expedicao__c> expedicoes = new Map<Id, Expedicao__c>();
                    
                    Map<Id,OpportunityLineItem> customs = new Map<Id, OpportunityLineItem>();
                    Set<String> newCodes = new Set<String>();
                    Set<String> newSizes = new Set<String>();
                    List<TempOli> tempList = new List<TempOli>();
                    
                    if(dossier.linhas_doss != null){
                        for(DossierLinha linha : dossier.linhas_doss){
                            OpportunityLineItem item;
                            system.debug(linha);
                            //boolean linhaCativa = linha.cativo.toLowerCase() == 'true';
                            //Se a linha tiver Id SF
                            if(linha.sf_id != ''){
                                
                                item = linhasExistentes.containsKey(linha.sf_id)
                                    ? linhasExistentes.get(linha.sf_id).clone() : new OpportunityLineItem();
                                
                                /*verifica se a linha da resposta tem stock cativo e se a linha original tem stock cativo
* se não tiver igual, significa que a linha terá de ser partida, ou que houve cativação de stock numa linha não cativa
*/
                                
                                if(Test.isRunningTest() || (item.Product2Id != null && item.Product2.RecordType.DeveloperName == 'Produto')){
                                    if(item.Stock_cativo__c != linha.cativo){
                                        doBreak = true;
                                        system.debug('vai partir linha;');
                                        if(linha.cativo){
                                            linhasExistentes.get(item.Id_Original__c).Quantity += linha.quant;
                                            customs.put(linha.sf_id, linhasExistentes.get(item.Id_Original__c));
                                            if(linha.lotes != ''){
                                                linhasExistentes.get(item.Id_Original__c).Alocacao_de_Stock__c +=
                                                    linha.arma + ' - ' + String.valueOf(linha.lotes) + ' - ' + linha.quant + ';\r\n';
                                            }
                                            item.Id = item.Id_Original__c;
                                            item.Total_de_customizacao__c = linha.preco_total;
                                            item.Quantity += linhasExistentes.get(item.Id_Original__c).Quantity;
                                        }else{
                                            item.Id_Original__c = linha.sf_id;
                                            if(linha.lotes != ''){
                                                item.Alocacao_de_Stock__c = linha.arma + ' - ' + String.valueOf(linha.lotes) + ' - ' + linha.quant + ';\r\n';
                                            }else{
                                                item.Alocacao_de_Stock__c = Label.Em_Falta + ' - ' + linha.quant + ';\r\n';
                                                //RP
                                                //item.Peso__c =  Double.valueOf((Double.valueOf(item.Product2.Peso_caixa__c) / Double.valueOf(item.Product2.Caixa_interior_unidades__c)) * item.quantity);
                                            }
                                            item.Quantity = linha.quant;
                                            item.Total_de_customizacao__c = linha.preco_total;
                                            customs.put(linha.sf_id, linhasExistentes.get(linha.sf_id));
                                            newOlis.put(item.Id_Original__c ,item);
                                        }
                                    }else{
                                        system.debug('mesma linha somar stock;');
                                        item.Id = linha.sf_id;
                                        item.Quantity += linha.quant;
                                        if(linha.peso != null) item.Peso__c = item.Peso__c != null ? item.Peso__c + linha.peso : linha.peso;
                                        if(linha.volume != null) item.Volume__c = item.Volume__c != null ? item.Volume__c + linha.volume : linha.volume;
                                        if(linha.preco_total != null) item.Total_de_customizacao__c = item.Total_de_customizacao__c != null ? item.Total_de_customizacao__c
                                            + linha.preco_total : linha.preco_total;
                                        if(item.Product2.RecordType.DeveloperName == 'Produto'){
                                            if(linha.lotes != ''){
                                                item.Alocacao_de_Stock__c += (item.Alocacao_de_Stock__c == '' ? '' : '\r\n')
                                                    + linha.arma + ' - ' 
                                                    + (linha.lotes != '' ? String.valueOf(linha.lotes) + ' - ' : '')
                                                    + linha.quant + ';';
                                            }else if(!linha.cativo){
                                                item.Alocacao_de_Stock__c += Label.Em_Falta + ' - ' + linha.quant + ';';
                                                //RP
                                                //item.Peso__c =  Double.valueOf((Double.valueOf(item.Product2.Peso_caixa__c) / Double.valueOf(item.Product2.Caixa_interior_unidades__c)) * item.quantity);
                                            }
                                        }
                                        linhasExistentes.put(linha.sf_id, item);
                                    }
                                    if(linha.stamp != null && item.Stamp__c != linha.stamp.trim()) item.Stamp__c = linha.stamp;
                                    
                                    if(linha.des_prod != null) item.Description = linha.des_prod;
                                    if(linha.preco_unit != null) item.Preco_unitario__c = linha.preco_unit;
                                    if(linha.altura != null) item.Altura__c = linha.altura;
                                    if(linha.comp_impressao != null && linha.comp_impressao != '-') 
                                        item.Componente_da_impressao__c = linha.comp_impressao;
                                    if(linha.comprimento != null) item.Comprimento__c = linha.comprimento;
                                    if(linha.cores_cust != null && linha.cores_cust != '-' && linha.cores_cust != '0') item.Cores_de_customizacao__c = linha.cores_cust;
                                    if(linha.n_impressoes != null) item.Numero_de_impressoes__c = linha.n_impressoes;
                                    if(linha.n_repeticoes != null) item.Numero_de_repeticoes__c = linha.n_repeticoes;
                                    if(linha.tecnica != null && linha.tecnica != '-') item.Tecnica__c = linha.tecnica;
                                    if(linha.cativo != null) item.Stock_cativo__c = linha.cativo;
                                    if(linha.tef_log != null && item.Expedicao__c != null)
                                        expedicoes.put(item.Expedicao__c, new Expedicao__c(Id = item.Expedicao__c, Telefone_logistico__c = linha.tef_log));
                                    if(item.Id == null)item.TotalPrice = null;
                                    if(item.Id != null) listOli.put(item.Id, item);
                                    else newOlis.put(item.Id_Original__c ,item);
                                }
                            }else{//linha nova
                                item = new OpportunityLineItem();
                                
                                item.OpportunityId = opp.Id;
                                if(linha.peso != null) item.Peso__c = linha.peso;
                                if(linha.lotes != null) item.Alocacao_de_Stock__c = linha.arma + ' - ' 
                                    + (String.valueOf(linha.lotes) != 'Em Falta' ? String.valueOf(linha.lotes) : Label.Em_Falta)
                                    + ' - ' + linha.quant;
                                item.Quantity = linha.quant;
                                if(linha.volume != null) item.Volume__c = linha.volume;
                                if(linha.preco_total != null) item.Total_de_customizacao__c = linha.preco_total;
                                if(linha.stamp != null) item.Stamp__c = linha.stamp;
                                if(linha.ref_sku != null) item.Referencia_SKU__c = linha.ref_sku;
                                if(linha.des_prod != null) item.Description = linha.des_prod;
                                if(linha.txt_cust != null && linha.txt_cust != '-') item.Texto_a_customizar__c = linha.txt_cust
                                    ;
                                if(linha.fonte != null && linha.fonte != '-') item.Fonte__c = linha.fonte;
                                if(linha.alinhamento != null) item.Alinhamento__c = String.valueOf((Integer)linha.alinhamento);
                                if(linha.preco_unit != null) {
                                    item.Preco_unitario__c = linha.preco_unit;
                                    item.UnitPrice = linha.preco_unit;
                                }
                                
                                if(linha.altura != null) item.Altura__c = linha.altura;
                                if(linha.comp_impressao != null && linha.comp_impressao != '-') 
                                    item.Componente_da_impressao__c = linha.comp_impressao;
                                if(linha.comprimento != null) item.Comprimento__c = linha.comprimento;
                                if(linha.cores_cust != null && linha.cores_cust != '-' && linha.cores_cust != '0') item.Cores_de_customizacao__c = linha.cores_cust;
                                if(linha.n_impressoes != null) item.Numero_de_impressoes__c = linha.n_impressoes;
                                if(linha.n_repeticoes != null) item.Numero_de_repeticoes__c = linha.n_repeticoes;
                                if(linha.tecnica != null && linha.tecnica != '-') item.Tecnica__c = linha.tecnica;
                                //if(linha.Transportadora_xc != null && linha.Transportadora_xc != '-') item.Transportadora__c = linha.Transportadora_xc;
                                if(linha.cativo != null) item.Stock_cativo__c = linha.ref_sku == 'NSIMPEXTRA' ? true : linha.cativo;
                                
                                String code = linha.ref_sku != '' && linha.ref_sku.contains('.') ?
                                    linha.ref_sku.split('\\.')[0] : linha.ref_sku;
                                String color = linha.ref_sku != '' && linha.ref_sku.contains('.') ? 
                                    (linha.ref_sku.split('\\.')[1].contains('-') ? 
                                     linha.ref_sku.split('\\.')[1].split('-')[0] : linha.ref_sku.split('\\.')[1])
                                    : '';
                                String size = linha.ref_sku != '' && linha.ref_sku.contains('-') ? linha.ref_sku.split('-')[1] : '';
                                item.Codigo_de_cor__c = color;
                                item.Tamanho__c = size;
                                //LINHAS CRIADAS PELO PHC TEM DE TER ESTE CAMPO A 1 PARA O DOSSIER PODER SER AUTORIZADO 2018-09-07
                                //TEM DE SER MONTADO UM SISTEMA PARA COMEÇAR A CRIAR EXPEDIÇÕES QUANDO FOREM CRIADAS LINHAS A PARTIR DO PHC
                                item.Auxiliar_expedicao__c = 1;
                                
                                //RP
                                String alocacaoAux = item.Alocacao_de_Stock__c;
                                /*
if(alocacaoAux.contains(Label.Em_Falta)){
item.Peso__c =  Double.valueOf((Double.valueOf(item.Product2.Peso_caixa__c) / Double.valueOf(item.Product2.Caixa_interior_unidades__c)) * item.quantity);
}
*/                            
                                
                                TempOli temp = new TempOli(code, color, size, item);
                                /*if(linha.ref_sku == 'NSIMPEXTRA'){
item.Auxiliar_expedicao__c = 1;
}*/
                                
                                newCodes.add(code);
                                newSizes.add(size);
                                tempList.add(temp);//lista para mapear os pbes
                            }
                        }
                    }
                    
                    
                    system.debug('listOli '+ listOli);
                    
                    
                    if(!listOli.isEmpty()) upsert listOli.values();
                    if(!newOlis.isEmpty()) upsert newOlis.values();
                    if(!expedicoes.isEmpty()) update expedicoes.values();
                    Set<Id> deletedIds = new Set<Id>();
                    //Apaga todas as linhas não presentes nos items devolvidos
                    if(!listOli.isEmpty() || !newOlis.isEmpty()){
                        List<OpportunityLineItem> toDelete = [Select id From OpportunityLineItem 
                                                              Where OpportunityId = :opp.Id 
                                                              And Id Not In :listOli.keySet() 
                                                              And Id Not In :newOlis.values() 
                                                              And (Product2.RecordType.DeveloperName = 'Produto')];
                        system.debug(toDelete);
                        deletedIds = new Map<Id, OpportunityLineItem>(toDelete).keySet();
                        delete toDelete;
                    }
                    
                    //Se tiver customizações para partir
                    if(!customs.isEmpty()){
                        List<OpportunityLineItem> customOlis = new List<OpportunityLineItem>();
                        boolean isFirst = true;
                        String oliQuery = 'Select ';
                        for(String s : Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().keySet()){
                            if(Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().get(s).getDescribe().isAccessible()){
                                if(isFirst){
                                    isFirst= false;
                                }else{
                                    oliQuery += ',';
                                }
                                oliQuery += s;
                            }
                        }
                        
                        String lista = '(';
                        isFirst = true;
                        for(Id var : customs.keySet()){
                            if(isFirst){
                                isFirst = false;	
                            }else{
                                lista += ',';
                            }
                            lista += '\'' + var + '\'';
                        }
                        lista += ')';
                        system.debug('lista' + lista);
                        oliQuery += ' From OpportunityLineItem Where Referencia_Relacionada__c In ' + lista	;
                        for(OpportunityLineItem oli : Database.query(oliQuery)){
                            if(listOli.containsKey(oli.Referencia_relacionada__c)){
                                oli.Quantity = listOli.get(oli.Referencia_relacionada__c).Quantity;
                            }else if(newOlis.containsKey(oli.Referencia_relacionada__c)){
                                oli.Quantity = newOlis.get(oli.Referencia_relacionada__c).Quantity;
                            }
                            if(!deletedIds.contains(oli.Id)) customOlis.add(oli);
                            
                            OpportunityLineItem newOli = oli.clone();
                            newOli.Referencia_relacionada__c = newOlis.get(oli.Referencia_relacionada__c).Id;
                            newOli.Quantity = newOlis.get(oli.Referencia_relacionada__c).Quantity;
                            if(newOli.UnitPrice != null) newOli.TotalPrice = null;
                            customOlis.add(newOli);
                        }
                        
                        if(!customOlis.isEmpty()) {
                            upsert customOlis;
                            if(!deletedIds.isEmpty()) delete [Select id From OpportunityLineItem Where Referencia_Relacionada__c In :deletedIds];
                        }
                    }
                    
                    //Se tiver novos items para criar do PHC
                    if(!tempList.isEmpty()){
                        system.debug(newCodes);
                        system.debug(newSizes);
                        List<PricebookEntry> prods = new List<PricebookEntry>();
                        Map<String, PricebookEntry> products = new Map<String, PricebookEntry>();
                        for(PricebookEntry pbe : [select id, ProductCode,Product2.Tamanho__c,Product2.RecordType.DeveloperName From PricebookEntry Where 
                                                  Pricebook2Id = :opp.Pricebook2Id And CurrencyisoCode = :opp.CurrencyIsoCode
                                                  And ProductCode In :newCodes And Product2.Tamanho__c In :newSizes]){
                                                      products.put(pbe.ProductCode + (pbe.Product2.Tamanho__c != null ? pbe.Product2.Tamanho__c : ''), pbe);
                                                  }
                        List<OpportunityLineItem> createOlis = new List<OpportunityLineItem>();
                        system.debug(products);
                        for(TempOli temp : tempList){
                            string key = temp.prodCode + (temp.prodSize != null ? temp.prodSize : '');
                            if(products.containsKey(key)){
                                temp.oli.PricebookEntryId = products.get(key).Id;
                                if(products.get(key).Product2.RecordType.DeveloperName != 'Produto'){
                                    temp.oli.Alocacao_de_Stock__c = '';
                                }
                                createOlis.add(temp.oli);
                            }
                        }
                        
                        if(!createOlis.isEmpty()) insert createOlis;
                    }
                    //Mapear campos da opp***********************
                    Opportunity auxOpp = [Select Id, Description, Autorizada__c, Erro_comunicacao__c, Versao_enviada__c,Espera_de_integracao__c, 
                                          (Select Id From Expedicoes__r)
                                          from Opportunity Where Id = :opp.Id];
                    boolean updateOpp = false;
                    //auxOpp.Espera_de_integracao__c = false;
                    
                    //Keidy - Espera de integração com valor diferente do atual.
                    auxOpp.Espera_de_integracao__c = false;
                    
                    auxOpp.Erro_comunicacao__c = false;
                    //auxOpp.Versao_enviada__c = auxOpp.Versao_enviada__c != null ? auxOpp.Versao_enviada__c + 1 : 1;
                    if(dossier.msg_erro != null && dossier.msg_erro != ''){
                        system.debug('PRIMEIRA');
                        auxOpp.Description = auxOpp.Description != null ? auxOpp.Description + '\n' + System.now().format() + ': ' + dossier.msg_erro + ';' : System.now().format() + ': ' + dossier.msg_erro;
                        auxOpp.Erro_comunicacao__c = true;
                        updateOpp = true;
                    }
                    if(dossier.dat_fat == errorDate){ 
                        system.debug('SEGUNDA');
                        auxOpp.Description = auxOpp.Description != null ? auxOpp.Description + '\n' + System.now().format() + ': Erro integração;' : System.now().format() + ': Erro integração;';
                        auxOpp.Erro_comunicacao__c = true;
                        updateOpp = true;
                    }
                    if(auxOpp.Id == dossier.sf_id){
                        updateOpp = true;
                        if(auxOpp.Autorizada__c == '' || auxOpp.Autorizada__c == null){
                            if(dossier.ref_phc != 0){
                                system.debug('TERCEIRA');
                                if(dossier.stamp != null) auxOpp.Stamp__c = dossier.stamp;
                                if(dossier.sf_id != null) auxOpp.Id = dossier.sf_id;
                                if(dossier.n_vol != null) auxOpp.Numero_de_volumes__c = dossier.n_vol;
                                if(dossier.n_exp != null) auxOpp.N_de_expedicao__c = String.valueOf(dossier.n_exp);
                                //auxOpp.Volumes__c = String.valueOf(dossier.vol);
                                if(dossier.dat_fat != null && dossier.dat_fat > nullDate) auxOpp.Data_de_faturacao__c = dossier.dat_fat.date();
                                if(dossier.cust_transp_stricker != null) auxOpp.Custo_de_transporte_Stricker__c = dossier.cust_transp_stricker;
                                if(dossier.dat_conc_prod != null && dossier.dat_fat > nullDate)
                                    auxOpp.Data_de_conclusao_de_producao__c = dossier.dat_conc_prod;
                                if(dossier.nweb != null) auxOpp.Nweb__c = String.valueOf(dossier.nweb);
                                if(dossier.ref_phc != null) auxOpp.Referencia_PHC__c = String.valueOf(dossier.ref_phc);
                                //auxOpp.Erro__c = dossier.erros;
                                if(dossier.dat_fecho != null && dossier.dat_fecho >= nullDate) auxOpp.CloseDate = dossier.dat_fecho.date();
                                if(dossier.logi4 != null) auxOpp.Nao_calcula_portes_automaticos__c = dossier.logi4;
                                //if(dossier.n_maq_aceite != null && dossier.n_maq_aceite != '') auxOpp.Nao_calcula_portes_automaticos__c = dossier.n_maq_aceite;
                                //Keidy - Quando o tab1 == 'ANULADO' o stageName da opp passa para 'Fechado anulado'.
                                if(dossier.tab1 != null && dossier.tab1 == 'ANULADO'){
                                    auxOpp.StageName = 'Fechado anulado';
                                }else //Quando o tab1 == 'Fechado faturado' o stageName da opp passa para 'Fechado faturado'
                                    if(dossier.tab1 != null && dossier.tab1.toLowerCase() == 'fechado faturado'){
                                    auxOpp.StageName = 'Fechado faturado';
                                }
                            }else{
                                auxOpp.Erro_comunicacao__c = true;
                            }
                            if(!auxOpp.Erro_comunicacao__c && auxOpp.Expedicoes__r.isEmpty()) auxOpp.Espera_de_integracao__c = doBreak;
                            else auxOpp.Espera_de_integracao__c = false;
                        }
                    }
                    system.debug(doBreak);
                    if(updateOpp) update auxOpp;
                    if(doBreak){
                        scheduleUpsert(auxOpp.Id, auxOpp.Stamp__c);
                    }
                }
                else{
                    Opportunity auxOpp = [Select Id, Description, Autorizada__c, Erro_comunicacao__c, Espera_de_integracao__c, Versao_enviada__c from Opportunity Where Id = :opp.Id];
                    
                    auxOpp.Erro_comunicacao__c = false;
                    auxOpp.Versao_enviada__c = auxOpp.Versao_enviada__c != null ? auxOpp.Versao_enviada__c + 1 : 1;
                    if(dossier.msg_erro != null && dossier.msg_erro != ''){
                        auxOpp.Description = auxOpp.Description != null ? auxOpp.Description + '\n' + System.now().format() + ': ' + dossier.msg_erro + ';' : System.now().format() + ': ' + dossier.msg_erro;
                        auxOpp.Erro_comunicacao__c = true;
                    }
                    if(dossier.dat_fat == errorDate){ 
                        auxOpp.Description = auxOpp.Description != null ? auxOpp.Description + '\n' + System.now().format() + ': Erro integração;' : System.now().format() + ': Erro integração;';
                        auxOpp.Erro_comunicacao__c = true;
                    }
                    //auxOpp.Espera_de_integracao__c = false;
                    
                    //Keidy - Espera de integração com valor diferente do atual.
                    auxOpp.Espera_de_integracao__c = false;
                    
                    try{
                        update auxOpp;
                        if(doBreak){
                            scheduleUpsert(auxOpp.Id, auxOpp.Stamp__c);
                        }
                    }catch(Exception Ex){
                        UtilClaims.sendEmailFailure('Falha de update dossier autorizado', '' + auxOpp + '\r\n' + ex.getMessage());      
                        if(doBreak){
                            scheduleUpsert(auxOpp.Id, auxOpp.Stamp__c);
                        }
                        if(!ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){ return new DossierReturn('1', ex.getMessage(), false);}
                        else{
                            return new DossierReturn('0', '', true);
                        }
                    }
                }
                
                return new DossierReturn('0', '', true);
            }else{
                return new DossierReturn('0', '', true);
            }
        }catch(Exception ex){
            system.debug(ex.getMessage() + 'Line: ' + ex.getLineNumber());
            return new DossierReturn('1', ex.getMessage() + 'Line: ' + ex.getLineNumber(), false);
        }
    }
    public static void scheduleUpsert(Id oppId, String oppStamp){
        DateTime now  = DateTime.now();
        String nowToString = String.ValueOf(now);
        DateTime nextRunTime = now.addSeconds(10);
        String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() +
            ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
        
        sh_UpsertDossierPHC sc = new sh_UpsertDossierPHC(oppId, oppStamp == null);
        System.schedule('sh_UpsertDossierPHC - Upsert dossier ' + oppId + ' - '+ nowToString, cronString, sc);
    }
    
    global class DossierReturn{
        webservice String erro;
        webservice String tipo_erro;
        webservice boolean dossier;
        
        public DossierReturn(String erro, String tipo_erro, boolean dossier){
            this.erro = erro;
            this.tipo_erro = tipo_erro;
            this.dossier = dossier;
        }
    }
    
    global class DossierRetorno {
        webservice String stamp;
        webservice String sf_id;
        webservice Decimal n_vol;
        webservice Decimal n_exp;
        webservice Decimal vol;
        webservice DateTime dat_fat;
        webservice Decimal cust_transp_stricker;
        webservice DateTime dat_conc_prod;
        webservice Decimal nweb;
        webservice Decimal ref_phc;
        webservice DateTime dat_fecho;
        webservice Integer erros;
        webservice String msg_erro;
        webservice String tab1;
        webservice Boolean logi4;
        webservice String n_maq_aceite;
        webservice List<DossierLinha> linhas_doss;
    }
    
    global class DossierLinha {
        webservice String stamp;
        webservice String sf_id;
        webservice String ref_sku;
        webservice String des_prod;
        webservice String txt_cust;
        webservice String fonte;
        webservice Decimal alinhamento;
        webservice Decimal quant;
        webservice Decimal preco_total;
        webservice Decimal preco_unit;
        webservice String nome_contact;
        webservice String cuidado_de;
        webservice Decimal n_seq_morada;
        webservice String morada_entrega;
        webservice String cod_post_morada;
        webservice String local_morada;
        webservice String cod_pais_morada;
        webservice String nome_pais_morada;
        webservice Decimal altura;
        webservice String comp_impressao;
        webservice Decimal comprimento;
        webservice String cores_cust;
        webservice Decimal n_impressoes;
        webservice Decimal n_repeticoes;
        webservice String tecnica;
        webservice String transp;
        webservice Boolean cativo;
        webservice String tef_log;
        webservice Decimal volume;
        webservice Decimal peso;
        webservice String lotes;
        webservice Integer arma;
        webservice String ref_rel;
        webservice String pantone;
        webservice String local_impressao;
        webservice String tab_imp;
        webservice Decimal preco_esc_a;
        webservice Decimal p_esc_original;
        webservice String valor_tabela;
    }
    
    public class TempOli{
        public String prodCode;
        public String prodColor;
        public String prodSize;
        public OpportunityLineItem oli;
        
        public TempOli(String prodCode, String prodColor, String prodSize, OpportunityLineItem oli){
            this.prodCode = prodCode;
            this.prodColor = prodColor;
            this.prodSize = prodSize;
            this.oli = oli;
        }
    }
}