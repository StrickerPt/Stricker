/* @Autor: Marco Galvão
* @Ultima Modificação: Marco Galvão
* Batch para executar um processo de sincronização de dossiers modificados em PHC já existentes em salesforce
* ESTA CLASSE SUBSTITUI OLD_b_UpdateDossier 
* */
public class b_UpdateDossierWeb implements Database.Batchable<Integer>,Database.AllowsCallouts, Database.Stateful, Schedulable{
    public static Map<String,Id> records {get{
        Map<String,Id> retRec = new Map<String, Id>();
        for(RecordType rt : [Select id, DeveloperName From RecordType Where SObjectType = 'Opportunity']){
            if(rt.DeveloperName == 'Folha_de_Obra'){
                retRec.put('32',rt.Id);
            }else if(rt.DeveloperName == 'Folha_de_Obra_de_Importacao'){
                retRec.put('40',rt.Id);
            }else if(rt.DeveloperName == 'Nota_de_encomenda'){
                retRec.put('2',rt.Id);
            }else if(rt.DeveloperName == 'Orcamento'){
                retRec.put('26',rt.Id);
            }else if(rt.DeveloperName == 'Orcamento_de_Importacao'){
                retRec.put('35',rt.Id);
            }else if(rt.DeveloperName == 'Reserva'){
                retRec.put('27',rt.Id);
            }
        }
        return retRec;
    }set;}
    
    //@hammer: variável para controlo da tabela vinda do site
    public Set<String> tabImpInvalidas = new Set<String>{'4A','5','8'};
    //@endHammer
    public List<Integer> start(Database.BatchableContext BC){
        try{
            Integrator.servico.timeout_x = 120000;
            Integrator.servico.endpoint_x = 'http://93.108.232.59:5006/clientStricker.asmx';
            
            clientStricker.ListaDossiersPHC resultado = Integrator.servico.lstDossiersWEB(1);
            system.debug(resultado);
            List<Integer> pages = new List<Integer>();
            for(Integer i = 1; i <= resultado.numtotalPaginas ; i++){
                pages.add(i);
            }
            return pages;
        }catch(Exception ex){
            UtilClaims.sendEmailFailure('Falha batch Dossiers Web', 'Batch de dossiers web falha: ' + ex.getMessage() + ' Line: ' + ex.getLineNumber());
            return new List<Integer>();
        }
    }
    
    public void execute(Database.BatchableContext BC, List<Integer> scope){
        try{
            Integrator.servico.timeout_x = 120000;
            Integrator.servico.endpoint_x = 'http://93.108.232.59:5006/clientStricker.asmx';
            checkRecursive.runFalse();
            Map<String,ID> users = new Map<String,ID>();
            for(User u :[select Id,Name from User where IsActive = true]){
                users.put(u.Name, u.Id);
            }
            
            List<clientStricker.ListaDossiersPHC> resultados = new List<clientStricker.ListaDossiersPHC>();
            
            for(Integer pagina : scope){
                try{
                    clientStricker.ListaDossiersPHC resultado = Integrator.servico.lstDossiersWEB(pagina); 
                    
                    resultados.add(resultado);
                }catch(Exception ex){
                    UtilClaims.sendEmailFailure('Falha dossiers Web', ex.getMessage() + ' ' + ex.getLineNumber() + ' \r\n Na página ' + pagina);
                }
            }
            
            //LISTA DE DOSSIERS RECEBIDOS
            Map<String,Opportunity> oppsToUpdate = new Map<String,Opportunity>();
            //LISTA DE LINHAS RECEBIDAS
            List<OpportunityLineItem> listOli = new List<OpportunityLineItem>();
            //LISTA DE CUSTOMIZAÇÕES RECEBIDAS
            List<OpportunityLineItem> custListOli = new List<OpportunityLineItem>();
            
            //SETS PARA SELECTS DE VALIDAÇÃO DE DADOS
            Set<String> idCliente = new Set<String>();
            Set<String> idRefs = new Set<String>();
            Set<String> idTamanho = new Set<String>();
            
            //SETS PARA SELECTS DE VALIDAÇÃO DE DADOS
            Set<String> oppStamps = new Set<String>();
            Set<String> oliStamps = new Set<String>();
            
            for(clientStricker.ListaDossiersPHC  r : resultados){
                if(r.listaDossiers != null && r.listaDossiers.DossierCabLST != null){
                    for(clientStricker.DossierCabLST dossier : r.listaDossiers.DossierCabLST){
                        oppStamps.add(dossier.st.trim());
                        if(dossier.listaLinhasDossiers != null && dossier.listaLinhasDossiers.DossierLinhaLST != null){
                            for(clientStricker.DossierLinhaLST linha: dossier.listaLinhasDossiers.DossierLinhaLST){
                                String ref = (linha.sku.contains('.') ? linha.sku.split('\\.')[0] : linha.sku);
                                String tam = (linha.sku.contains('-') ? linha.sku.split('-')[1] : '');
                                
                                idRefs.add(ref);
                                idTamanho.add(tam);
                                oliStamps.add(linha.stlinha.trim());
                            }
                            idCliente.add(dossier.numCliente);
                        }
                    }
                }
            }
            //chaves de produtos
            Map<String, Product2> produtos = new Map<String, Product2>();
            for(Product2 prod : [Select id,ProductCode, Tamanho__c, Referencia_relacionada__c,Tabela_de_customizacoes__c,Id_Componente__c, Id_Local__c,
                                 RecordType.DeveloperName,Localizacao_da_impressao__c, Tecnica__c,Altura_maxima__c,Comprimento_maximo__c,Cores_de_customizacao__c, Componente_da_impressao__c
                                 From Product2 Where 
                                 isActive = true And
                                 ((ProductCode in :idRefs And RecordType.DeveloperName != 'Customizacao') Or
                                  (Referencia_Relacionada__c in :idRefs And ProductCode in :idRefs)) And
                                 (Tamanho__c In :idTamanho Or Tamanho__c = null)]){
                                     
                                     if(prod.RecordType.DeveloperName != 'Customizacao'){ produtos.put(prod.ProductCode + (prod.Tamanho__c != null ? '-' + prod.Tamanho__c : ''), prod);}
                                     else{
                                         produtos.put(Utils.buildChaveCustomizacao(prod), prod);
                                     }
                                 }
            
            Map<String, Account> pricebookKeys = new Map<String, Account>();//Numero Cliente / Mercado
            Map<String, Pricebook2> pricebookmap = new Map<String, Pricebook2>(); //Mercado / Pricebook2
            
            //chaves de clientes
            Set<String> mercados = new Set<String>();
            for(Account acc : [Select Id, Tabela_de_precos__c, CurrencyIsoCode,Numero_de_cliente__c, OwnerId From Account Where Numero_de_cliente__c In :idCliente]){
                pricebookKeys.put(acc.Numero_de_cliente__c, acc);
                mercados.add(acc.Tabela_de_precos__c);
            }
            
            //chaves de mercados
            for(Pricebook2 pb: [Select id, Mercado__c From Pricebook2 Where Mercado__c In :mercados]){
                pricebookMap.put(pb.Mercado__c, pb);
            }
            if(Test.isRunningTest()) pricebookmap.put('1', new Pricebook2(Id = Test.getStandardPricebookId(), Mercado__c = '1'));
            
            //set para guardar as opps já existentes -> erro de overwrite do nome com 'New Opp'
            Set<String> existingOpps = new Set<String>();
            
            Set<String> existingStamps = new Set<String>();
            //validar se opportunity e item já existem
            for(Opportunity opp: [Select id, Stamp__c, (Select Id, Stamp__c From OpportunityLineItems Where Stamp__c In :oliStamps) From Opportunity Where Stamp__c In :oppStamps]){
                existingOpps.add(opp.Stamp__c);
                for(OpportunityLineItem oli : opp.OpportunityLineItems){
                    if(oli.Stamp__c != null) existingStamps.addAll(oli.Stamp__c.split(';'));
                }
            }
            
            Map<String, String> oppStampsMap = new Map<String, String>();//oli.stamp / opp.stamp
            Datetime nullDate = Datetime.newInstance(2000, 1, 1);
            
            //set para verificar se estamos a adicionar linhas duplicadas
            Set<String> biStamps = new Set<String>();
            
            for(clientStricker.ListaDossiersPHC  r : resultados){
                if(r.listaDossiers != null && r.listaDossiers.DossierCabLST != null){
                    for(clientStricker.DossierCabLST dossier : r.listaDossiers.DossierCabLST){
                        if(dossier.ndos == '2' || dossier.ndos == '32'){
                            if(pricebookKeys.containsKey(dossier.numCliente)){
                                
                                Opportunity opp = new Opportunity();
                                if(!existingOpps.contains(dossier.st.trim())){
                                    opp.Name = 'New Opp'; //2018-08-27 adicionado if para nao fazer overwrite ao nome
                                    opp.StageName = 'Aberto';
                                }
                                opp.Origem__c = 'Web';
                                
                                if(dossier.fase == 'Fechado anulado') opp.StageName = dossier.fase;//2018-08-27
                                
                                opp.Account = new Account(Numero_de_Cliente__c = dossier.numCliente);
                                if(dossier.st.trim() != null) opp.Stamp__c = dossier.st.trim();
                                if(dossier.idsfdos != null && dossier.idsfdos.trim() != '') opp.Id = dossier.idsfdos;
                                if(dossier.refint != null) opp.Referencia_interna__c = dossier.refint;
                                if(dossier.motpen != null) opp.Motivo_de_pendente__c = dossier.motpen;
                                if(dossier.ndos != null) opp.RecordTypeId = records.get(dossier.ndos);
                                if(dossier.estdmaqte != null) opp.Estado_da_maquete__c = dossier.estdmaqte;
                                if(dossier.emailmaqte != null) opp.Email_para_envio_de_maquete__c = dossier.emailmaqte.contains(';') ? dossier.emailmaqte.split(';')[0] : dossier.emailmaqte;
                                if(dossier.nvmaqteaceite != null){
                                    String versao;
                                    List<String> splittedVers = dossier.nvmaqteaceite.split('\\.');
                                    if(splittedVers.size() > 1){
                                        if(dossier.nvmaqteaceite.split('\\.')[1].isNumeric()) versao = dossier.nvmaqteaceite.split('\\.')[1];
                                        else versao = '1';
                                    }else{
                                        versao = '1';
                                    }
                                    opp.N_de_versao_de_maquete_aceite__c = Decimal.valueOf(versao);
                                }
                                if(dossier.dtapeddmaqte != null && dossier.dtapeddmaqte > nullDate) opp.Data_do_pedido_de_maquete__c = dossier.dtapeddmaqte;
                                if(dossier.dtaaprovmaqte != null && dossier.dtaaprovmaqte > nullDate) opp.Data_de_aprovacao_de_maquete__c = dossier.dtaaprovmaqte;
                                if(dossier.dtalimitprod != null && dossier.dtalimitprod > nullDate) opp.Data_limite_de_producao__c = dossier.dtalimitprod;
                                if(dossier.docdest != null) opp.Documento_de_destino__c = dossier.docdest;
                                if(dossier.amostra != null) opp.Amostra__c = dossier.amostra;
                                //opp = dossier.tipfact; CAMPO DA CONTA
                                if(dossier.custotranspStr != null) opp.Custo_de_transporte_Stricker__c = dossier.custotranspStr;
                                if(dossier.nexp != null) opp.N_de_expedicao__c = dossier.nexp;
                                if(dossier.dtafact != null && dossier.dtafact > nullDate) opp.Data_de_faturacao__c = dossier.dtafact.date();
                                if(dossier.nvol != null) opp.Numero_de_volumes__c = dossier.nvol;
                                //if(dossier.vol != null) opp.Volumes__c = String.valueOf(dossier.vol);
                                if(dossier.dtaconclprod != null && dossier.dtaconclprod > nullDate) opp.Data_de_conclusao_de_producao__c = dossier.dtaconclprod;
                                if(dossier.nweb != null) opp.Nweb__c = String.valueOf(dossier.nweb);
                                if(dossier.Referencia_PHC_xc != '') opp.Referencia_PHC__c = dossier.Referencia_PHC_xc;
                                if(dossier.Armazem_xc != null && dossier.Armazem_xc != 0) opp.Armazem__c = String.valueOf(Integer.valueOf(dossier.Armazem_xc));
                                if(dossier.Notas_de_expedicao_xc != '') opp.Notas_de_expedicao__c = dossier.Notas_de_expedicao_xc;
                                if(dossier.DataEnvio_xc > nullDate) opp.Data_de_Envio__c = dossier.DataEnvio_xc;
                                if(dossier.logi4 != null) opp.Nao_calcula_portes_automaticos__c = dossier.logi4;
                                
                                if(dossier.ndos == '2'){
                                    //adicionado a 2018-08-02 para as encomendas poderem ser autorizadas no PHC
                                    if(dossier.autorizada != null && dossier.autorizada.trim() != ''){
                                        opp.Autorizada__c = dossier.autorizada;
                                        if( (dossier.nexp == null || dossier.nexp == '')){
                                            opp.StageName = 'Armazém';
                                        }else if(opp.Data_de_faturacao__c != null){
                                            opp.StageName = 'Fechado faturado';
                                        }else{
                                            opp.StageName = 'Em processo de faturação';
                                        }
                                    }
                                }else if(dossier.ndos == '32'){
                                    if(dossier.autorizada != null && dossier.autorizada.trim() != ''){
                                        opp.Autorizada__c = dossier.autorizada;
                                        if( (dossier.nexp != null && dossier.nexp != '')){
                                            opp.StageName = 'Em processo de faturação';
                                        }else if(opp.Data_de_faturacao__c != null){
                                            opp.StageName = 'Fechado faturado';
                                        }else{
                                            opp.StageName = 'Em produção';
                                        }
                                    }
                                }
                                
                                opp.OwnerId = pricebookKeys.get(dossier.numCliente).OwnerId;
                                opp.CloseDate = system.today().addMonths(1);
                                opp.CurrencyIsoCode = ProductManager.mapISOCodes.get(pricebookKeys.get(dossier.numCliente).Tabela_de_precos__c);
                                //pricebookKeys.get(dossier.numCliente).CurrencyIsoCode;
                                
                                //Mapas para o mapeamento entre as linhas base e as linhas de costumização, para permitir o mapeamento de customizações através do bistamp para alem do Id SF
                                Map<String, String> mapProdsCusts = new Map<String, String>();//ref base, bistamp LINHAS PRINCIPAIS
                                Map<String, List<OpportunityLineItem>> customs = new Map<String, List<OpportunityLineItem>>();//refrel, List<oli> CUSTOMIZAÇÕES
                                
                                if(dossier.listaLinhasDossiers != null && dossier.listaLinhasDossiers.DossierLinhaLST != null){
                                    for(clientStricker.DossierLinhaLST linha: dossier.listaLinhasDossiers.DossierLinhaLST){
                                        if(linha.transp != null && linha.transp != '') opp.Transportadora_online__c = linha.transp;
                                        if(linha.sku != 'NSPCE' && linha.sku != 'NSDESPACHCLI' && linha.sku != 'NSPTER' && linha.sku != 'NSPORTES'){
                                            //2018-08-27 adicionado para impedir criação de linhas em duplicado
                                            if(!biStamps.contains(linha.stlinha.trim())){
                                                
                                                biStamps.add(linha.stlinha.trim());
                                                
                                                OpportunityLineItem item = new OpportunityLineItem();
                                                
                                                if(opp.Morada_de_entrega_online__c == null && linha.rua != null) opp.Morada_de_entrega_online__c = linha.rua;
                                                if(opp.Pais_online__c == null && linha.codpais != null && linha.codpais != '00') opp.Pais_online__c = linha.codpais;
                                                if(opp.Codigo_postal_online__c == null && linha.cp != null) opp.Codigo_postal_online__c = linha.cp;
                                                if(opp.Localidade_online__c == null && linha.local != null) opp.Localidade_online__c = linha.local;
                                                if(opp.Ao_cuidado_de_online__c == null && linha.utrab4 != null) opp.Ao_cuidado_de_online__c = linha.utrab4;
                                                
                                                if(linha.stlinha.trim() != null) item.Stamp__c = linha.stlinha.trim();
                                                if(linha.sku != null) item.Referencia_SKU__c = linha.sku;
                                                if(linha.sku.contains('.')){
                                                    if(linha.sku.contains('-')){
                                                        String[] hifenSplit = linha.sku.split('-');
                                                        
                                                        String[] dotSplit =  hifenSplit[0].split('\\.');
                                                        item.Codigo_de_cor__c = dotSplit[dotSplit.size() - 1];
                                                    }else{
                                                        String[] dotSplit =  linha.sku.split('\\.');
                                                        item.Codigo_de_cor__c = dotSplit[dotSplit.size() - 1];
                                                    }
                                                }
                                                if(linha.design != null) item.Description = linha.design;
                                                if(linha.texto != null) item.Texto_a_customizar__c = linha.texto;
                                                if(linha.font != null) item.Fonte__c = linha.font;
                                                if(linha.alinh != null) item.Alinhamento__c = String.valueOf((Integer) linha.alinh);
                                                if(linha.prcunit != null) item.Preco_unitario__c = linha.prcunit;
                                                if(linha.alt != null) item.Altura__c = linha.alt;
                                                if(linha.compimpre != null) item.Componente_da_impressao__c = linha.compimpre;
                                                if(linha.comp != null) item.Comprimento__c = linha.comp;
                                                if(linha.corcust != null) item.Cores_de_customizacao__c = linha.corcust;
                                                if(linha.nimp != null) item.Numero_de_impressoes__c = linha.nimp > 0 ? linha.nimp : 1;
                                                if(linha.nrep != null) item.Numero_de_repeticoes__c = linha.nrep > 0 ? linha.nrep : 1;
                                                if(linha.tecn != null) item.Tecnica__c = linha.tecn;
                                                if(linha.qtt != null) item.Quantity = linha.qtt;
                                                if(linha.ttprc != null) item.TotalPrice = linha.ttprc;
                                                if(linha.ttprc != null) item.Total_de_customizacao__c = linha.ttprc;
                                                if(linha.transp != null) item.Transportadora__c = linha.transp;
                                                if(linha.pantone != null) item.Pantone_Cor__c = linha.pantone;
                                                
                                                //alterado para true, de 'linha.cativo' para que as linhas sejam criadas 
                                                //sempre com o stock a tentar cativar para que o comercial nao tenha de picar todas as linhas
                                                if(linha.cativo != null) item.Stock_cativo__c = true;
                                                
                                                if(linha.tlflog != null) opp.Telefone_logistico__c = linha.tlflog;
                                                if(linha.vol != null) item.Volume__c = linha.vol;
                                                if(linha.peso != null) item.Peso__c = linha.peso;
                                                if(linha.lote != null) item.Lotes__c = String.valueOf(linha.lote);
                                                if(linha.arm != null) item.Armazem__c = linha.arm;
                                                
                                                String sfRef = linha.sku.contains('.') ? linha.sku.split('\\.')[0] : linha.sku;
                                                String sfTam = linha.sku.contains('-') ? '-' + linha.sku.split('-')[1] : '';
                                                item.Alocacao_de_Stock__c = linha.arm + ' - ' + (linha.lote != '' ? linha.lote + ' - ' : '') + linha.qtt + ';';
                                                if(opp.Autorizada__c != null && opp.Autorizada__c != '') item.Auxiliar_expedicao__c = 1;
                                                //PRODUTOS BASE
                                                if(produtos.containsKey(sfRef + sfTam)){
                                                    
                                                    //guardar referencia base e o seu bistamp
                                                    mapProdsCusts.put(linha.sku, linha.stlinha.trim());
                                                    
                                                    if(!existingStamps.contains(linha.stlinha.trim())){
                                                        system.debug(pricebookMap);
                                                        system.debug(pricebookKeys.get(dossier.numCliente).Tabela_de_precos__c);
                                                        String aux = produtos.get(sfRef + sfTam).Id + '' + pricebookMap.get(pricebookKeys.get(dossier.numCliente).Tabela_de_precos__c).Id + '' + 
                                                            ProductManager.mapISOCodes.get(pricebookKeys.get(dossier.numCliente).Tabela_de_precos__c);
                                                        item.PricebookEntry = new PricebookEntry(ChaveExterna__c = aux);
                                                    }
                                                    listOli.add(item);
                                                }else{ 
                                                    
                                                    //@hammer: validar tabela por limitação do site
                                                    if(tabImpInvalidas.contains(linha.tecn)){
                                                        linha.tecn = linha.tecn + '-' + linha.corcust;
                                                    }
                                                    //@endHammer
                                                    String refBase = '';
                                                    if(linha.refrel.contains('.')){
                                                        refBase += linha.refrel.split('\\.')[0];
                                                    }
                                                    if(linha.refrel.contains('-')){
                                                        refBase += '-' + linha.refrel.split('-')[1];
                                                    }
                                                    if(refBase == '') refBase = linha.refrel;
                                                    system.debug(linha);
                                                    String auxKey = Utils.buildChaveCustomizacao(Utils.buildProduto(refBase, linha.tecn, linha.idC, linha.idL, linha.corcust));
                                                    system.debug(auxKey);
                                                    if(produtos.containsKey(auxKey)){
                                                        //VALIDA SE LINHA JÁ EXISTE POR PREENCHIMENTO DO PRICEBOOKENTRYID
                                                        if(!existingStamps.contains(linha.stlinha.trim())){ //CUSTOMIZACOES
                                                            String aux = produtos.get(auxKey).Id + '' + pricebookMap.get(pricebookKeys.get(dossier.numCliente).Tabela_de_precos__c).Id + '' + 
                                                                ProductManager.mapISOCodes.get(pricebookKeys.get(dossier.numCliente).Tabela_de_precos__c);
                                                            item.PricebookEntry = new PricebookEntry(ChaveExterna__c = aux);
                                                            
                                                            //@new
                                                            if(!customs.containsKey(linha.refrel)) customs.put(linha.refrel, new List<OpportunityLineItem>());
                                                            customs.get(linha.refrel).add(item);
                                                            //@endNew
                                                        }
                                                        custListOli.add(item);
                                                    }
                                                }
                                                oppStampsMap.put(linha.stlinha.trim(), dossier.st.trim());
                                                
                                            }
                                        }
                                    }
                                }
                                oppsToUpdate.put(opp.stamp__c, opp);
                                
                                //preencher para cada customização deste dossier o seu bistamp / referencia relacionada
                                for(String refrel : customs.keySet()){
                                    for(OpportunityLineItem cust : customs.get(refrel)){
                                        if(mapProdsCusts.containsKey(refrel)){
                                            cust.Referencia_relacionada_original__c = refrel;
                                            cust.Referencia_relacionada__c = mapProdsCusts.get(refrel);
                                        }else{
                                            system.debug('Não encontrei refrel');
                                        }
                                    }
                                }
                                
                            }else{
                                system.debug('Cliente não existe: ' + dossier.numCliente);
                            }
                        }
                    }
                }
            }
            
            try{
                if(!oppsToUpdate.isEmpty()) {
                    checkRecursive.runOpportunityAfterUpdate = false;
                    checkRecursive.runOpportunityBeforeUpdate = false;
                    
                    Database.UpsertResult[] oppResults = Database.upsert(oppsToUpdate.values(), Opportunity.Stamp__c, false);
                    
                    for(Database.UpsertResult res : oppResults){
                        if(!res.isSuccess()){
                            system.debug(LoggingLevel.INFO,res.getErrors() + ' : ' + res.getId());
                        }
                    }
                }
                
                for(OpportunityLineItem oli: listOli){
                    oli.OpportunityId = oppsToUpdate.get(oppStampsMap.get(oli.stamp__c)).Id;
                }
                for(OpportunityLineItem oli: custListOli){
                    oli.OpportunityId = oppsToUpdate.get(oppStampsMap.get(oli.stamp__c)).Id;
                }
                if(!listOli.isEmpty()){
                    Database.UpsertResult[] oliResults = Database.upsert(listOli, OpportunityLineItem.Stamp__c, false);
                    
                    for(Database.UpsertResult res : oliResults){
                        if(!res.isSuccess()){
                            system.debug(LoggingLevel.INFO,res.getErrors());
                        }
                    }
                }
                if(!custListOli.isEmpty()){
                    Database.UpsertResult[] oliResults = Database.upsert(custListOli, OpportunityLineItem.Stamp__c, false);
                    
                    for(Database.UpsertResult res : oliResults){
                        if(!res.isSuccess()){
                            system.debug(LoggingLevel.INFO,res.getId() + ' ' +res.getErrors());
                        }
                    }
                }
                if(!oppsToUpdate.isEmpty() && !oppStampsMap.isEmpty()) delete [Select id from OpportunityLineItem Where Opportunity.Stamp__c In :oppsToUpdate.keySet() And Stamp__c Not in :oppStampsMap.keySet()];
                
            }catch(Exception ex){
                system.debug(ex.getMessage() + ' ' + ex.getLineNumber() );
                UtilClaims.sendEmailFailure('Falha dossiers Web', ex.getMessage() + ' ' + ex.getLineNumber() + ' \r\n Nas páginas ' + scope );
            }
        }catch(Exception ex){
                system.debug(ex.getMessage() + ' ' + ex.getLineNumber() );
            UtilClaims.sendEmailFailure('Falha update dossiers web','Batch update Dossiers Web Falha: ' + ex.getMessage() + ' ; ' + ex.getLineNumber() + '\r\nPáginas: ' + scope);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        
        checkRecursive.runFalse();
        //CORRIGIR STAMPS
        Map<String, OpportunityLineItem> refRels = new Map<String, OpportunityLineItem>();
        //vai buscar linhas de customização e as suas referencias relacionadas recebidas
        for(OpportunityLineItem Oli : [select id, Referencia_relacionada__c, OpportunityId from OpportunityLineItem 
                                       Where Product2.RecordType.DeveloperName = 'Customizacao' 
                                       and opportunity.Origem__c = 'Web' 
                                       and opportunity.recordType.DeveloperName = 'Folha_de_Obra'
                                       and Referencia_relacionada__c != ''
                                       and (not Referencia_relacionada__c  Like '%00k%')]){
                                           refRels.put(oli.Referencia_relacionada__c, oli);
                                       }
        
        //vai buscar as linhas principais cujos stamps foram encontrados correspondencia da linha da customização
        List<OpportunityLineItem> olis = [Select Id,Stamp__c From OpportunityLineItem Where Stamp__c In :refRels.keySet()];
        Set<String> Stampsprods = new Set<String>();
        for(OpportunityLineItem oli : olis){
            if(!refRels.containsKey(oli.Stamp__c)){
                system.debug('Não encontrou stamp');
                UtilClaims.sendEmailFailure('Falha na correcção da referencia relacionada', 'Opportunity: ' + oli.OpportunityId + '\r\nOpportunityLineItem: ' + oli
                                           + '\r\nLinhas Customização: ' + refRels);
            }else{
                refRels.get(oli.Stamp__c).Referencia_relacionada__c = oli.Id;
            }

        }
        update refRels.values();
        
        
        //@toDo:ENVIAR RESULTADOS PARA PHC
        reprogramSelf();
    }
    
    public void execute(System.SchedulableContext SC){
        Database.executeBatch(this, 1);
    }
    
    
    public static void reprogramSelf(){
        DateTime now  = DateTime.now();
        String nowToString = String.ValueOf(now);
        DateTime nextRunTime = now.addMinutes(10);
        String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
        
        b_UpdateDossierWeb sc = new b_UpdateDossierWeb();
        if(!Test.isRunningTest()) System.schedule('Reagendamento - b_UpdateDossierWeb '+nowToString, cronString, sc);
    }
}