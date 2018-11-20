/* @Autor: Marco Galvão
 * @Ultima Modificação: Marco Galvão
 * Batch para executar um processo de sincronização de dossiers modificados em PHC já existentes em salesforce
 * ESTA CLASSE SUBSTITUI OLD_b_UpdateDossier 
 * */
public class b_UpdateDossier implements Database.Batchable<Integer>,Database.AllowsCallouts, Database.Stateful, Schedulable{
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
    
    public List<Integer> start(Database.BatchableContext BC){
        try{
            Integrator.servico.timeout_x = 120000;
            //Integrator.servico.endpoint_x = 'http://93.108.232.59:5006/clientStricker.asmx';
            
            clientStricker.ListaDossiersPHC resultado = Integrator.servico.lstDossiersPHC(1);
            system.debug(resultado);
            List<Integer> pages = new List<Integer>();
            for(Integer i = 1; i <= resultado.numtotalPaginas ; i++){
                pages.add(i);
            }
            return pages;
        }catch(Exception ex){
            UtilClaims.sendEmailFailure('Falha batch Dossiers PHC', 'Batch de dossiers PHC falha: ' + ex.getMessage() + ' Line: ' + ex.getLineNumber());
            return new List<Integer>();
        }
    }
    
    public void execute(Database.BatchableContext BC, List<Integer> scope){
        try{
            Integrator.servico.timeout_x = 120000;
            checkRecursive.runFalse();
            //Integrator.servico.endpoint_x = 'http://93.108.232.59:5006/clientStricker.asmx';
            
            Map<String,ID> users = new Map<String,ID>();
            for(User u :[select Id,Name from User where IsActive = true]){
                users.put(u.Name, u.Id);
            }
            
            List<clientStricker.ListaDossiersPHC> resultados = new List<clientStricker.ListaDossiersPHC>();
            system.debug(scope);
            //FAZER PEDIDO/PEDIDOS
            for(Integer pagina : scope){
                clientStricker.ListaDossiersPHC resultado = Integrator.servico.lstDossiersPHC(pagina); 
                
                resultados.add(resultado);
            }
            
            system.debug(resultados);
            //LISTA DE DOSSIERS RECEBIDOS
            Map<String,Opportunity> oppsToUpdate = new Map<String,Opportunity>();
            //LISTA DE LINHAS RECEBIDAS
            List<OpportunityLineItem> listOli = new List<OpportunityLineItem>();
            
            
            //SETS PARA SELECTS DE VALIDAÇÃO DE DADOS
            Set<String> idCliente = new Set<String>();
            Set<String> idRefs = new Set<String>();
            Set<String> idTamanho = new Set<String>();
            
            //
            Set<String> oppStamps = new Set<String>();
            Set<String> validateOppIds = new Set<String>();
            Set<String> oliStamps = new Set<String>();
            
            for(clientStricker.ListaDossiersPHC  r : resultados){
                if(r.listaDossiers != null && r.listaDossiers.DossierCabLST != null){
                    for(clientStricker.DossierCabLST dossier : r.listaDossiers.DossierCabLST){
                        oppStamps.add(dossier.st.trim());
                        validateOppIds.add(dossier.idsfdos.trim());
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
            for(Account acc : [Select Id, Tabela_de_precos__c, CurrencyIsoCode,Numero_de_cliente__c From Account Where Numero_de_cliente__c In :idCliente]){
                pricebookKeys.put(acc.Numero_de_cliente__c, acc);
                mercados.add(acc.Tabela_de_precos__c);
            }
            
            //chaves de mercados
            for(Pricebook2 pb: [Select id, Mercado__c From Pricebook2 Where Mercado__c In :mercados]){
                pricebookMap.put(pb.Mercado__c, pb);
            }
            if(Test.isRunningTest()) pricebookmap.put('1', new Pricebook2(Id = Test.getStandardPricebookId(), Mercado__c = '1'));
            
            Set<String> existingStamps = new Set<String>();
            //validar se opportunity e item já existem
            for(Opportunity opp: [Select id, (Select Id, Stamp__c From OpportunityLineItems Where Stamp__c In :oliStamps) From Opportunity Where Stamp__c In :oppStamps]){
                for(OpportunityLineItem oli : opp.OpportunityLineItems){
                    if(oli.Stamp__c != null) existingStamps.addAll(oli.Stamp__c.split(';'));
                }
            }
            
            //MAPA PARA VALIDAR SE OPP JÁ AUTORIZADA
            Map<Id, Opportunity> oppMap = new Map<Id,Opportunity>([Select id, Espera_de_integracao__c, Autorizada__c, N_de_versao_de_maquete_aceite__c from Opportunity Where Id In :validateOppIds]);
            
            //VARIAVEIS AUXILIARES
            Map<Id, OpportunityLineItem> olisMap = new Map<Id, OpportunityLineItem>();
            Set<Id> oppIds = new Set<Id>();
            Datetime nullDate = Datetime.newInstance(2000, 1, 1);
            
            //set para verificar se estamos a adicionar linhas duplicadas
            Set<String> biStamps = new Set<String>();
            
            //TRATAR DOSSIERS
            for(clientStricker.ListaDossiersPHC  r : resultados){
                if(r.listaDossiers != null && r.listaDossiers.DossierCabLST != null){
                    for(clientStricker.DossierCabLST dossier : r.listaDossiers.DossierCabLST){
                        //system.debug(oppMap.containsKey(dossier.idsfdos) && !oppMap.get(dossier.idsfdos).Espera_de_integracao__c);
                        if(pricebookKeys.containsKey(dossier.numCliente) && (dossier.idsfdos != null && oppMap.containsKey(dossier.idsfdos) && !oppMap.get(dossier.idsfdos).Espera_de_integracao__c)){
                            Opportunity opp = new Opportunity();
                            
                            //opp.StageName = dossier.fase != null && dossier.fase != '' ? dossier.fase : 'Aberto';
                            if(dossier.fase == 'Fechado anulado') opp.StageName = dossier.fase;
                            opp.Account = new Account(Numero_de_Cliente__c = dossier.numCliente);
                            if(dossier.st.trim() != null) opp.Stamp__c = dossier.st.trim();
                            if(dossier.idsfdos != null) opp.Id = dossier.idsfdos;
                            if(dossier.refint != null) opp.Referencia_interna__c = dossier.refint;
                            //if(dossier.motpen != null) opp.Motivo_de_pendente__c = dossier.motpen;
                            if(dossier.ndos != null) opp.RecordTypeId = records.get(dossier.ndos);
                            //if(dossier.estdmaqte != null) opp.Estado_da_maquete__c = dossier.estdmaqte == 'Em aprovação do cl' ? 'Em aprovação do cliente' : dossier.estdmaqte;
                            if(dossier.emailmaqte != null) opp.Email_para_envio_de_maquete__c = dossier.emailmaqte;
                            //Alterado a 31-10-2018 para o campo N_de_versao_de_maquete_aceite__c nao ser atualizado pelo batch
                            /*
                            if(dossier.nvmaqteaceite != null && oppMap.containsKey(dossier.idsfdos) && oppMap.get(dossier.idsfdos).N_de_versao_de_maquete_aceite__c != null ) {
                                //Alterado a 12-02-2018 por o campo estar a vir com o texto: Versão. sem vir preenchido
                                String versao = dossier.nvmaqteaceite.contains('.') ?(dossier.nvmaqteaceite.split('\\.').size() > 1 ? dossier.nvmaqteaceite.split('\\.')[1] : '' ):'1';
                                opp.N_de_versao_de_maquete_aceite__c = versao != '' ? Decimal.valueOf(versao) : null;
                            }
                            */
                            //2018-10-12 if(dossier.dtapeddmaqte != null && dossier.dtapeddmaqte > nullDate) opp.Data_do_pedido_de_maquete__c = dossier.dtapeddmaqte;
                            if(dossier.dtaaprovmaqte != null && dossier.dtaaprovmaqte > nullDate) opp.Data_de_aprovacao_de_maquete__c = dossier.dtaaprovmaqte;
                            // 2018/09/10 passou a Data_de_conclusao_de_producao__c - if(dossier.dtalimitprod != null && dossier.dtalimitprod > nullDate) opp.Data_limite_de_producao__c = dossier.dtalimitprod;
                            if(dossier.dtalimitprod != null && dossier.dtalimitprod > nullDate) opp.Data_de_conclusao_de_producao__c = dossier.dtalimitprod;
                            if(dossier.docdest != null) opp.Documento_de_destino__c = dossier.docdest;
                            if(dossier.amostra != null) opp.Amostra__c = dossier.amostra;
                            //op. = dossier.tipfact; CAMPO DA CONTA
                            if(dossier.custotranspStr != null) opp.Custo_de_transporte_Stricker__c = dossier.custotranspStr;
                            if(dossier.nexp != null) opp.N_de_expedicao__c = dossier.nexp;
                            if(dossier.dtafact != null && dossier.dtafact > nullDate) opp.Data_de_faturacao__c = dossier.dtafact.date();
                            if(dossier.nvol != null) opp.Numero_de_volumes__c = dossier.nvol;
                            
                            if(dossier.dtaconclprod != null && dossier.dtaconclprod > nullDate) opp.Data_de_conclusao_de_producao__c = dossier.dtaconclprod;
                            if(dossier.nweb != null) opp.Nweb__c = String.valueOf(dossier.nweb);
                            if(dossier.DataEnvio_xc != null && dossier.DataEnvio_xc > nullDate) opp.Data_de_envio__c = dossier.DataEnvio_xc;
                            if(dossier.CloseDate != null && dossier.CloseDate > nullDate) opp.CloseDate = dossier.CloseDate.date();
                            if(dossier.logi4 != null) opp.Nao_calcula_portes_automaticos__c = dossier.logi4;
                            //adicionado a 2018-08-02 para as encomendas poderem ser autorizadas no PHC
                            if((dossier.autorizada != null && dossier.autorizada != '') && (oppMap.get(dossier.idsfdos).Autorizada__c == '' || oppMap.get(dossier.idsfdos).Autorizada__c == null)){
                                opp.Autorizada__c = dossier.autorizada;
                                opp.StageName = 'Armazém';
                            }
                            //opp.CurrencyIsoCode = pricebookKeys.get(dossier.numCliente).CurrencyIsoCode;
                            
                            // 2018/09/10 campos novos  FO 
                            //if(dossier.vol != null) opp.Volumes__c = String.valueOf(dossier.vol);
                            if(dossier.Armazem_xc != null) opp.Armazem__c = String.valueOf(dossier.Armazem_xc);
                            if(dossier.Notas_de_expedicao_xc != null) opp.Notas_de_expedicao__c = dossier.Notas_de_expedicao_xc;
                            if(dossier.SLA != null) opp.SLA__c = dossier.SLA;
                            
                            
                            if(dossier.listaLinhasDossiers != null && dossier.listaLinhasDossiers.DossierLinhaLST != null){
                                for(clientStricker.DossierLinhaLST linha: dossier.listaLinhasDossiers.DossierLinhaLST){
                                    
                                    if(!biStamps.contains(linha.stlinha.trim())){
                                        biStamps.add(linha.stlinha.trim());
                                        if(linha.idsflinha == null || linha.idsflinha.trim() == ''){//criar nova linha
                                            OpportunityLineItem item = new OpportunityLineItem();
                                            
                                            item.OpportunityId = opp.Id;
                                            if(linha.stlinha.trim() != null) item.Stamp__c = linha.stlinha.trim();
                                            if(linha.sku != null) item.Referencia_SKU__c = linha.sku;
                                            if(linha.design != null) item.Description = linha.design;
                                            if(linha.texto != null) item.Texto_a_customizar__c = linha.texto;
                                            if(linha.font != null) item.Fonte__c = linha.font;
                                            if(linha.alinh != null) item.Alinhamento__c = String.valueOf((Integer) linha.alinh);
                                            if(linha.qtt != null) item.Quantity = linha.qtt;
                                            if(linha.ttprc != null) item.TotalPrice = linha.ttprc;
                                            if(linha.ttprc != null) item.Total_de_customizacao__c = linha.ttprc;
                                            if(linha.prcunit != null) item.Preco_unitario__c = linha.prcunit;
                                            if(linha.alt != null) item.Altura__c = linha.alt;
                                            if(linha.compimpre != null) item.Componente_da_impressao__c = linha.compimpre;
                                            if(linha.comp != null) item.Comprimento__c = linha.comp;
                                            if(linha.corcust != null) item.Cores_de_customizacao__c = linha.corcust;
                                            if(linha.nimp != null) item.Numero_de_impressoes__c = linha.nimp;
                                            if(linha.nrep != null) item.Numero_de_repeticoes__c = linha.nrep;
                                            if(linha.tecn != null) item.Tecnica__c = linha.tecn;
                                            if(linha.transp != null) item.Transportadora__c = linha.transp;
                                            if(linha.cativo != null) item.Stock_cativo__c = linha.cativo;
                                            if(linha.tlflog != null) opp.Telefone_logistico__c = linha.tlflog;
                                            if(linha.vol != null) item.Volume__c = linha.vol;
                                            if(linha.peso != null) item.Peso__c = linha.peso;
                                            if(linha.lote != null) item.Lotes__c = linha.lote;
                                            if(linha.arm != null) item.Armazem__c = linha.arm;
                                            if(c_AddProduct.transpCodes.contains(item.Referencia_SKU__c)) item.Auxiliar_expedicao__c = 1;
                                            item.Alocacao_de_Stock__c = linha.arm + ' - ' + (linha.lote != '' ? linha.lote + ' - ' : '') + linha.qtt + ';';
                                            String sfRef = linha.sku.contains('.') ? linha.sku.split('\\.')[0] : linha.sku;
                                            String sfTam = linha.sku.contains('-') ? '-' + linha.sku.split('-')[1] : '';
                                            
                                            //PRODUTOS BASE
                                            system.debug(sfRef + sfTam);
                                            system.debug(produtos);
                                            if(produtos.containsKey(sfRef + sfTam)){
                                                if(!existingStamps.contains(linha.stlinha.trim())){
                                                    String aux = produtos.get(sfRef + sfTam).Id + '' + pricebookMap.get(pricebookKeys.get(dossier.numCliente).Tabela_de_precos__c).Id + '' + 
                                                        ProductManager.mapISOCodes.get(pricebookKeys.get(dossier.numCliente).Tabela_de_precos__c);
                                                    item.PricebookEntry = new PricebookEntry(ChaveExterna__c = aux);
                                                }
                                                listOli.add(item);
                                            }else if(!Test.isRunningTest()){ //CUSTOMIZACOES
                                                String auxKey = Utils.buildChaveCustomizacao(Utils.buildProduto(linha.refrel, linha.tecn, linha.compimpre, linha.locImp, linha.corcust));
                                                system.debug(auxKey);
                                                if(produtos.containsKey(auxKey)){
                                                    String aux = produtos.get(auxKey).Id + '' + pricebookMap.get(pricebookKeys.get(dossier.numCliente).Tabela_de_precos__c).Id + '' + 
                                                        ProductManager.mapISOCodes.get(pricebookKeys.get(dossier.numCliente).Tabela_de_precos__c);
                                                    item.PricebookEntry = new PricebookEntry(ChaveExterna__c = aux);
                                                    
                                                    listOli.add(item);
                                                }else{
                                                    system.debug('Correspondência de produto não encontrada.');
                                                }
                                            }
                                        }else{
                                            String key = linha.idsflinha.trim();
                                            if(!olisMap.containsKey(key)) olisMap.put(key, new OpportunityLineItem(Id = linha.idsflinha));
                                            OpportunityLineItem thisLine = olisMap.get(key);
                                            
                                            //Campos comuns
                                            if(linha.texto != null) thisLine.Texto_a_customizar__c = linha.texto;
                                            if(linha.font != null) thisLine.Fonte__c = linha.font;
                                            if(linha.alinh != null) thisLine.Alinhamento__c = String.valueOf((Integer) linha.alinh);
                                            if(linha.prcunit != null) thisLine.Preco_unitario__c = linha.prcunit;
                                            if(linha.alt != null) thisLine.Altura__c = linha.alt;
                                            if(linha.compimpre != null) thisLine.Componente_da_impressao__c = linha.compimpre;
                                            if(linha.comp != null) thisLine.Comprimento__c = linha.comp;
                                            if(linha.corcust != null) thisLine.Cores_de_customizacao__c = linha.corcust;
                                            if(linha.nimp != null) thisLine.Numero_de_impressoes__c = linha.nimp;
                                            if(linha.nrep != null) thisLine.Numero_de_repeticoes__c = linha.nrep;
                                            if(linha.tecn != null) thisLine.Tecnica__c = linha.tecn;
                                            if(linha.transp != null) thisLine.Transportadora__c = linha.transp;
                                            if(linha.cativo != null) thisLine.Stock_cativo__c = linha.cativo;
                                            if(linha.tlflog != null) opp.Telefone_logistico__c = linha.tlflog;
                                            if(linha.arm != null) thisLine.Armazem__c = linha.arm;
                                            if(linha.sku != null) thisLine.Referencia_SKU__c = linha.sku;
                                            if(linha.sku != null) thisLine.Codigo_de_cor__c = linha.sku.contains('.') ? linha.sku.split('\\.')[1] : '';
                                            
                                            //Campos aditivos
                                            if(linha.qtt != null) thisLine.Quantity = thisLine.Quantity != null ? thisLine.Quantity + linha.qtt : linha.qtt;
                                            if(linha.ttprc != null) thisLine.TotalPrice = thisLine.TotalPrice != null ? thisLine.TotalPrice + linha.ttprc : linha.ttprc;
                                            if(linha.ttprc != null) thisLine.Total_de_customizacao__c = thisLine.TotalPrice;
                                            if(linha.vol != null) thisLine.Volume__c = thisLine.Volume__c != null ? thisLine.Volume__c + linha.vol : linha.vol;
                                            if(linha.peso != null) thisLine.Peso__c = thisLine.Peso__c != null ? thisLine.Peso__c + linha.peso : linha.peso;
                                            if(linha.lote != null) thisLine.Lotes__c = thisLine.Lotes__c != null ? thisLine.Lotes__c + '\r\n' + linha.lote : linha.lote;
                                            thisLine.Alocacao_de_Stock__c = thisLine.Alocacao_de_Stock__c != null ? 
                                                thisLine.Alocacao_de_Stock__c + '\r\n' + linha.arm + ' - ' + (linha.lote.trim() != '' ? linha.lote + ' - ' : '') + linha.qtt + ';' 
                                                : + linha.arm + ' - ' + (linha.lote.trim() != '' ? linha.lote + ' - ' : '') + linha.qtt + ';';
                                            
                                            
                                            
                                            
                                            olisMap.put(key, thisLine);
                                        }
                                    }      
                                }        
                            }
                            oppsToUpdate.put(opp.stamp__c, opp);
                            oppIds.add(opp.Id);
                        }else{
                            system.debug(LoggingLevel.INFO,'Cliente não existe' + dossier.numCliente);
                        }
                    }
                }
            }//FIM TRATAR DOSSIERS
            
            //ATUALIZA OPORTUNIDADES
            if(!oppsToUpdate.isEmpty()) {

                Database.UpsertResult[] oppResults = Database.upsert(oppsToUpdate.values(), false);
                
                for(Database.UpsertResult res : oppResults){
                    system.debug(LoggingLevel.INFO,res.getErrors());
                }
            }
            
            //CRIAR LINHAS NOVAS
            if(!listOli.isEmpty()){
                Database.UpsertResult[] oliResults = Database.upsert(listOli, false);
                
                for(Database.UpsertResult res : oliResults){
                    system.debug(LoggingLevel.INFO,res.getErrors());
                }
            }
            
            //ATUALIZAR LINHAS QUE VIERAM COM IDSF
            if(!olisMap.isEmpty()){
                system.debug(olisMap.values());
                Database.UpsertResult[] oliResults2 = Database.upsert(olisMap.values(), false);
                
                for(Database.UpsertResult res : oliResults2){
                    system.debug(LoggingLevel.INFO,res.getErrors());
                }
            }
            
            //APAGAR LINHAS QUE NÃO VIERAM NO BATCH NEM FORAM CRIADAS
            if(!oppIds.isEmpty() && !olisMap.isEmpty()) delete [Select id from opportunityLineitem 
                                                                Where OpportunityId In :oppIds 
                                                                And Id Not In :olisMap.values() 
                                                                And Id Not In :listOli
                                                               /*And ProductCode Not In :c_AddProduct.transpCodes @toDo: resolver o apagar linha de portes com preço 0*/];
            
            
           //@toDo: AGRUPAR AS LINHAS E O SEU RESULTADO PARA PODER ENVIAR NO FINAL DO BATCH CORRER
        }catch(Exception ex){
            UtilClaims.sendEmailFailure('Falha update dossiers','Batch update Dossiers Falha: ' + ex.getMessage() + ' ; ' + ex.getLineNumber() + '\r\nPáginas: ' + scope);
        }
    }
    
    public void execute(System.SchedulableContext SC){
        Database.executeBatch(this, 2);
    }
    
    public void finish(Database.BatchableContext BC){
        //@toDo:ENVIAR RESULTADOS PARA PHC
        reprogramSelf();
    }
    
    public static void reprogramSelf(){
        DateTime now  = DateTime.now();
        String nowToString = String.ValueOf(now);
        DateTime nextRunTime = now.addMinutes(30);
        String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
        
        b_UpdateDossier sc = new b_UpdateDossier();
        if(!Test.isRunningTest()) System.schedule('Reagendamento - b_UpdateDossier '+nowToString, cronString, sc);
    }
}