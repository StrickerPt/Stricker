global class ProductManager{
    
    public static Map<String,ID> mapRTypes = new Map<String,ID>();
    public static Map<String,Traducao_Custom__mdt> mapTraducoesCustom = new Map<String,Traducao_Custom__mdt>();
    public static Map<String,ID> mapPricebook = new Map<String,ID>();
    public static List<Product2> produtosToUpsert = new List<Product2>();
    public static List<Product2> produtosCustomizacaoToUpsert = new List<Product2>();
    public static List<PricebookEntry> pbToUpsert = new List<PricebookEntry>();
    public static List<PricebookEntry> pbCustomizacaoToUpsert = new List<PricebookEntry>();
    public static List<clientStricker.Produto> productValues = new List<clientStricker.Produto>();
    public static Map<String,String> mapISOCodes = new Map<String,String>{'1' => 'EUR','2' => 'EUR','3' => 'USD','4' => 'EUR','5' => 'GBP','6' => 'PLN','49' => 'EUR', '50' => 'EUR'};
    public static Set<String> taxCodes = new Set<String>{'NSPTER', 'NSPORTES', 'NSDESPACHCLI', 'NSTAXUSB', 'NSIMPEXTRA', 'NSTRANSP', 'NSPCE','NSGEN'};
    public static Id standardPBId {get;set;}
    public static boolean isPHC = false;
    
    public static final Integer nCallouts = 2;

    @future(callout=true)
    public static void initProdutos(Integer pagina, Integer maxPagina, String ultimaData){
        isPHC = true;
        for(RecordType rt : [Select DeveloperName,Id From RecordType Where SobjectType= 'Product2']){
            mapRTypes.put(rt.DeveloperName,rt.Id);
        }
        for(Pricebook2 pb : [Select id,Mercado__c From Pricebook2 Where isStandard = false]){
            mapPricebook.put(pb.Mercado__c,pb.id);
        }
        
        if(!Test.isRunningTest()){
            standardPBId = [Select id From Pricebook2 Where isStandard = true].id;
        }else{
            standardPBId = Test.getStandardPricebookId();
        }
        
        Integer limitCallout = 1;
        Integrator.servico.timeout_x = 120000;
        //Integrator.servico.endpoint_x = 'http://93.108.232.59:5006/clientStricker.asmx';
        do {
            clientStricker.ListaProdutosPHC listaResponse = Integrator.servico.lstProdutosPHC(ultimaData, pagina);
            
            if(listaResponse.listaProdutos.Produto != null){
                runExecute(listaResponse.listaProdutos);
            }
            /*if(pagina == 1 && !Test.isRunningTest())*/ maxpagina = listaResponse.numtotalPaginas;
            pagina++;
            limitCallout++;
        }while(pagina <= maxPagina && limitCallout <= nCallouts);
        
        Database.UpsertResult[] srProdutos = DataBase.Upsert(produtosToUpsert,Product2.ChaveExterna__c, false);
        
        String errors = '';
        //verificar se falhou algum produto
        for(Database.UpsertResult result :srProdutos){
            system.debug(result.isSuccess());
            if(!result.isSuccess()){
                errors += result.getErrors() + '\r\n';
            }
        }
        
        if(errors != ''){
            UtilClaims.sendEmailFailure('Falha importação produtos PHC', errors);
        }
        
        runExecutePBE(srProdutos);
        
        Database.UpsertResult[] srPbe = DataBase.Upsert(pbToUpsert,PricebookEntry.ChaveExterna__c);

        runExecuteCustomizacoes(productValues);
        
        Database.UpsertResult[] srPbeC = DataBase.Upsert(pbCustomizacaoToUpsert,PricebookEntry.ChaveExterna__c);
        
        if(limitCallout >= nCallouts && pagina <= maxpagina){
            DateTime now  = DateTime.now();
            String nowToString = String.ValueOf(now);
            DateTime nextRunTime = now.addSeconds(15);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            
            
            sh_ProductManager sc = new sh_ProductManager(pagina, maxPagina, ultimaData);
            System.schedule('Reagendamento - sh_ProductManager '+nowToString, cronString, sc);
        }else{
            DateTime now  = DateTime.now();
            String nowToString = String.ValueOf(now);
            DateTime nextRunTime = now.addSeconds(15);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            
            
            sh_CustomManager sc = new sh_CustomManager(1, 1, ultimaData);
            System.schedule('Agendamento - sh_CustomManager '+nowToString, cronString, sc);
        }
    }
    
    @future(callout=true)
    public static void initCustomizacoes(Integer pagina, Integer maxPagina, String ultimaData){
        isPHC = false;
        for(RecordType rt : [Select DeveloperName,Id From RecordType Where SobjectType= 'Product2']){
            mapRTypes.put(rt.DeveloperName,rt.Id);    
        }
        for(Pricebook2 pb : [Select id,Mercado__c From Pricebook2 Where isStandard = false]){
            mapPricebook.put(pb.Mercado__c,pb.id);
        }
        for(Traducao_Custom__mdt tc: [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, Descricao_PT__c, Descricao_EN_US__c, Descricao_FR__c, Descricao_ES__c,
                                      Descricao_DE__c, Descricao_NL_NL__c, Descricao_IT__c, Descricao_PL__c, Descricao_RU__c 
                                      FROM Traducao_Custom__mdt]){
                                          mapTraducoesCustom.put(tc.DeveloperName, tc);            
        }
        if(!Test.isRunningTest()){
            standardPBId = [Select id From Pricebook2 Where isStandard = true].id;
        }else{
            standardPBId = Test.getStandardPricebookId();
        }
        
        Integer limitCallout = 1;
        Integrator.servico.timeout_x = 120000;
        //Integrator.servico.endpoint_x = 'http://93.108.232.59:5006/clientStricker.asmx';
        do {
            clientStricker.ListaProdutosPHC listaResponse = Integrator.servico.lstCustomizaPHC(ultimaData, pagina);
            
            if(listaResponse.listaProdutos.Produto != null){
                runExecute(listaResponse.listaProdutos);
            }
            /*if(pagina == 1 && !Test.isRunningTest())*/ maxpagina = listaResponse.numtotalPaginas;
            pagina++;
            limitCallout++;
            
        }while(pagina <= maxPagina && limitCallout <= nCallouts);
        
        Database.UpsertResult[] srProdutos = DataBase.Upsert(produtosToUpsert,Product2.ChaveExterna__c, false);
        String errors = '';
        //verificar se falhou algum produto
        for(Database.UpsertResult result :srProdutos){
            if(!result.isSuccess()){
                errors += result.getErrors() + '\r\n';
            }
        }
        if(errors != ''){
            UtilClaims.sendEmailFailure('Falha importação customiza', errors);
        }
        
        runExecutePBE(srProdutos);
        
        Database.UpsertResult[] srPbe = DataBase.Upsert(pbToUpsert,PricebookEntry.ChaveExterna__c);

        runExecuteCustomizacoes(productValues);

        Database.UpsertResult[] srPbeC = DataBase.Upsert(pbCustomizacaoToUpsert,PricebookEntry.ChaveExterna__c);
        
        
        if(limitCallout >= nCallouts && pagina <= maxpagina){
            DateTime now  = DateTime.now();
            String nowToString = String.ValueOf(now);
            DateTime nextRunTime = now.addSeconds(15);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            
            
            sh_CustomManager sc = new sh_CustomManager(pagina, maxPagina, ultimaData);
            System.schedule('Reagendamento - sh_CustomManager '+nowToString, cronString, sc);
        }
    }
    
    //Metodo para cria Produtos
    private static void runExecute(clientStricker.ArrayOfProduto listaProdutos){
        
        for(integer i = 0; i < listaProdutos.Produto.size(); ++i){
            clientStricker.Produto prod = listaProdutos.Produto[i];
            if(prod.refB != 'NSTRANS' && prod.refB != 'NSESTAMP'){
                productValues.add(prod);
                Product2 sProd = new Product2();
                sProd.Name = prod.NomePT;
                sProd.isActive = true;
                sProd.ProductCode = prod.refB.contains('-') ? prod.refB.subString(0,prod.refB.indexOf('-')) : prod.refB;
                sProd.RecordTypeId = taxCodes.contains(sProd.ProductCode) ? mapRTypes.get('Taxa') : mapRTypes.get('Produto');
                sProd.ChaveExterna__c = prod.refB;
                sProd.Tamanho__c = prod.Tam;
                sProd.Url_da_Imagem__c = prod.urlImagem;
                if(isPHC){
                    sProd.Nome_do_produto_pt_BR_PHC__c = prod.NomePT;
                    sProd.Nome_do_produto_en_US_PHC__c = prod.NomeEN;
                    sProd.Nome_do_produto_ES_PHC__c = prod.NomeES;
                    sProd.Nome_do_produto_it_PHC__c = prod.NomeIT;
                    sProd.Nome_do_produto_FR_PHC__c = prod.NomeFR;
                    sProd.Nome_do_produto_RU_PHC__c = prod.NomeRU;
                    sProd.Nome_do_produto_PL_PHC__c = prod.NomePL;
                    sProd.Nome_do_produto_NL_PHC__c = prod.NomeNL;
                    sProd.Nome_do_produto_DE_PHC__c = prod.NomeDE;
                    sProd.Descricao_do_produto_PT_BR_PHC__c = prod.DescPT;  
                    sProd.Descricao_do_produto_en_US_PHC__c = prod.DescEN;
                    sProd.Descricao_do_produto_ES_PHC__c = prod.DescES;
                    sProd.Descricao_do_produto_IT_PHC__c = prod.DescIT;
                    sProd.Descricao_do_produto_FR_PHC__c = prod.DescFR;
                    sProd.Descricao_do_produto_RU_PHC__c = prod.DescRU;
                    sProd.Descricao_do_produto_PL_PHC__c = prod.DescPL;
                    sProd.Descricao_do_produto_NL_PHC__c = prod.DescNL;
                    sProd.Descricao_do_produto_DE_PHC__c = prod.DescDE;
                }else{
                    sProd.Nome_do_produto_pt_BR__c = prod.NomePT;
                    sProd.Nome_do_produto_en_US__c = prod.NomeEN;
                    sProd.Nome_do_produto_ES__c = prod.NomeES;
                    sProd.Nome_do_produto_it__c = prod.NomeIT;
                    sProd.Nome_do_produto_FR__c = prod.NomeFR;
                    sProd.Nome_do_produto_RU__c = prod.NomeRU;
                    sProd.Nome_do_produto_PL__c = prod.NomePL;
                    sProd.Nome_do_produto_NL__c = prod.NomeNL;
                    sProd.Nome_do_produto_DE__c = prod.NomeDE;
                    sProd.Descricao_do_produto_PT__c = prod.DescPT;  
                    sProd.Descricao_do_produto_en_US__c = prod.DescEN;
                    sProd.Descricao_do_produto_ES__c = prod.DescES;
                    sProd.Descricao_do_produto_IT__c = prod.DescIT;
                    sProd.Descricao_do_produto_FR__c = prod.DescFR;
                    sProd.Descricao_do_produto_RU__c = prod.DescRU;
                    sProd.Descricao_do_produto_PL__c = prod.DescPL;
                    sProd.Descricao_do_produto_NL__c = prod.DescNL;
                    sProd.Descricao_do_produto_DE__c = prod.DescDE;
                }
                sProd.Catalogo__c = prod.Catalogo;
                sProd.Capitulo__c = prod.Capitulo;
                sProd.Pagina_do_catalogo__c = prod.PCatalogo.isNumeric() ? Decimal.ValueOf(prod.PCatalogo) : null;
                sProd.Dimensoes__c = prod.DimProduto;
                sProd.Dimensoes_maximas_de_impressao__c = prod.DimImpressao;
                sProd.Cor__c = prod.Cor;
                sProd.Gramagem_de_produtos_complementares__c = prod.GrProdutoComp.isNumeric() ? Decimal.ValueOf(prod.GrProdutoComp) : null;
                sProd.Outros_materiais__c = prod.OMateriais;
                sProd.Caixa_exterior_medidas__c = prod.CExtM;
                sProd.Peso_caixa__c = prod.PesoC;
                sProd.Caixa_exterior_unidades__c = prod.CExtUN;
                sProd.Caixa_interior_unidades__c = prod.CIntUN;
                sProd.Taric__c = prod.Taric;
                sProd.Local_de_picking__c = prod.LPicking;
                sProd.Repacking__c = prod.Repacking == '0' ? false : true;
                sProd.Packing_individual__c = prod.PackingInd;
                sProd.Certificados__c = prod.Certificados;
                sProd.Tipo_de_carga_esferograficas__c = prod.TipoCarga;
                sProd.Pilhas_incluidas__c = prod.Pilhas;
                sProd.Tipo_de_pilha__c = prod.TipoPilhas;
                //sProd.Tipo_de_carga_esferograficas__c = prod.TipoCarga;
                sProd.Multiplicador_Produto__c = prod.Multiplicador != 0 && prod.Multiplicador != null ? prod.Multiplicador : 1;
                sProd.Usr3__c = prod.usr3;
                sProd.Peso__c = prod.pesoUni;
                sProd.Volume__c = prod.volUni;
                produtosToUpsert.add(sProd);
            }
        }
    }
    
    //Metodo para criar PricebookEntries dos produtos
    private static void runExecutePBE(Database.UpsertResult[] srProdutos){
        
        for(integer i = 0; i < productValues.size(); ++i){
            clientStricker.Produto prod = productValues[i];           
            List<clientStricker.Mercados> mercDoProd = prod.precosMercados.Mercados;
            
            if(mercDoProd != null && srProdutos[i].isSuccess()){
                Integer inte = 0;
                Set<string> duplicateSet = new Set<String>();
                for(clientStricker.Mercados merc : mercDoProd){

                    PricebookEntry pbe = new PricebookEntry();
                    if(srProdutos[i].isCreated()){
                        pbe.Product2Id = srProdutos[i].getId();
                        pbe.Pricebook2Id = mapPricebook.get(merc.codMercado);
                        pbe.CurrencyIsoCode = mapISOCodes.get(merc.codMercado);    
                    }
                    system.debug(srProdutos[i]);
                    pbe.ChaveExterna__c = srProdutos[i].getId() +''+ mapPricebook.get(merc.codMercado)+''+mapISOCodes.get(merc.codMercado);
                    if(!duplicateSet.contains(pbe.ChaveExterna__c)){
                        duplicateSet.add(pbe.ChaveExterna__c);
                        inte++;
                        pbe.UseStandardPrice = false;
                        pbe.UnitPrice = 0;
                        pbe.IsActive = true;
                        //PRECOS POR ESCALAO
                        pbe.Preco_A__c = merc.A != null ? merc.A : 0;
                        pbe.Preco_B__c = merc.B != null ? merc.B : 0;
                        pbe.Preco_C__c = merc.C != null ? merc.C : 0;
                        pbe.Preco_D__c = merc.D != null ? merc.D : 0;
                        pbe.Preco_E__c = merc.E != null ? merc.E : 0;
                        pbe.Preco_F__c = merc.F != null ? merc.F : 0;
                        pbe.Preco_G__c = merc.G != null ? merc.G : 0;
                        pbe.Preco_H__c = merc.H != null ? merc.H : 0;
                        pbe.Preco_I__c = merc.I != null ? merc.I : 0;
                        pbe.Preco_J__c = merc.J != null ? merc.J : 0;
                        pbe.Preco_O__c = merc.PO != null ? merc.PO : 0;
                        //pbe.Preco_K__c = merc.K != null ? merc.K : 0;
                        //pbe.Preco_L__c = merc.L != null ? merc.L : 0;
                        //pbe.Preco_M__c = merc.M != null ? merc.M : 0;
                        //pbe.Preco_N__c = merc.N != null ? merc.N : 0;
                        
                        //PRECOS POR QUANTIDADE
                        pbe.Preco_1__c = merc.P1 != null ? merc.P1 : 0;
                        pbe.Preco_2__c = merc.P2 != null ? merc.P2 : 0;
                        pbe.Preco_3__c = merc.P3 != null ? merc.P3 : 0;
                        pbe.Preco_4__c = merc.P4 != null ? merc.P4 : 0;
                        pbe.Preco_5__c = merc.P5 != null ? merc.P5 : 0;
                        pbe.Preco_6__c = merc.P6 != null ? merc.P6 : 0;
                        pbe.Preco_7__c = merc.P7 != null ? merc.P7 : 0;
                        pbe.Preco_8__c = merc.P8 != null ? merc.P8 : 0;
                        pbe.Preco_9__c = merc.P9 != null ? merc.P9 : 0;
                        pbe.Preco_10__c = merc.P10 != null ? merc.P10 : 0;
                        
                        //RANGES DAS QUANTIDADES
                        pbe.Minimo_1__c = merc.Min1 != null ? merc.Min1 : 0;
                        pbe.Minimo_2__c = merc.Min2 != null ? merc.Min2 : 0;
                        pbe.Minimo_3__c = merc.Min3 != null ? merc.Min3 : 0;
                        pbe.Minimo_4__c = merc.Min4 != null ? merc.Min4 : 0;
                        pbe.Minimo_5__c = merc.Min5 != null ? merc.Min5 : 0;
                        pbe.Minimo_6__c = merc.Min6 != null ? merc.Min6 : 0;
                        pbe.Minimo_7__c = merc.Min7 != null ? merc.Min7 : 0;
                        pbe.Minimo_8__c = merc.Min8 != null ? merc.Min8 : 0;
                        pbe.Minimo_9__c = merc.Min9 != null ? merc.Min9 : 0;
                        pbe.Minimo_10__c = merc.Min10 != null ? merc.Min10 : 0;
                        pbe.Maximo_1__c = merc.Max1 != null ? merc.Max1 : 0;
                        pbe.Maximo_2__c = merc.Max2 != null ? merc.Max2 : 0;
                        pbe.Maximo_3__c = merc.Max3 != null ? merc.Max3 : 0;
                        pbe.Maximo_4__c = merc.Max4 != null ? merc.Max4 : 0;
                        pbe.Maximo_5__c = merc.Max5 != null ? merc.Max5 : 0;
                        pbe.Maximo_6__c = merc.Max6 != null ? merc.Max6 : 0;
                        pbe.Maximo_7__c = merc.Max7 != null ? merc.Max7 : 0;
                        pbe.Maximo_8__c = merc.Max8 != null ? merc.Max8 : 0;
                        pbe.Maximo_9__c = merc.Max9 != null ? merc.Max9 : 0;
                        pbe.Maximo_10__c = merc.Max10 != null ? merc.Max10 : 0;

                        
                        pbToUpsert.add(pbe);
                        
                    }
                }
            }
        }
    }
    
    //Metodo para criar Customizacoes e respectivos PricebookEntries
    private static void runExecuteCustomizacoes(List<clientStricker.Produto> productValues){
        Map<String,customizacaoBuilder> mapCustomizacaoBuilder = new Map<String,customizacaoBuilder>(); 
        for(clientStricker.Produto prod : productValues){
            List<clientStricker.Customizacao> customizacoes = prod.customizacoes.Customizacao;
            if(customizacoes != null){
                for(clientStricker.Customizacao customizacao : customizacoes){
                    for(integer i = 1; i <= customizacao.ncol_precos_pers; ++i){
                        //String cKey = prod.refB +''+customizacao.TabPers+''+i+''+customizacao.c_Alt+''+customizacao.c_Larg + customizacao.Local;2018-01-30
                        //String cKey = prod.refB +''+customizacao.Compon+''+customizacao.Local+customizacao.TabPers+''+i+''+customizacao.c_Alt+customizacao.c_Larg+customizacao.c_Dim;//Alterado a 2018-09-03
                        String cKey = Utils.buildChaveCustomizacao(Utils.buildProduto(prod.refB, customizacao.TabPers, String.valueOf(customizacao.idC), String.valueOf(customizacao.idL), '' + i));
                        if(!mapCustomizacaoBuilder.containsKey(cKey)){
                            system.debug(cKey);
                        }
                        if(!mapCustomizacaoBuilder.containsKey(cKey)){
                            String textoC = '';
                            //verifica qual a coluna onde vem a designacao da customizacao
                            if(i == 1){
                                textoC = customizacao.c1;
                            }
                            else if(i == 2){
                                textoC = customizacao.c2;
                            }
                            else if(i == 3){
                                textoC = customizacao.c3;
                            }
                            else if(i == 4){
                                textoC = customizacao.c4;
                            }
                            else if(i == 5){
                                textoC = customizacao.c5;
                            }
                            String dimensoesDeImpressaoDaComponente = customizacao.Comp != 0 ? 
                                String.valueOf(customizacao.Comp).substring(0, String.valueOf(customizacao.Comp).indexOf('.'))
                                +'X'+String.valueOf(customizacao.Alt).substring(0, String.valueOf(customizacao.Alt).indexOf('.')) +' mm' :
                            '';
                            String dimensoesMaximasImpressao = customizacao.c_Larg != 0 ?
                                String.valueOf(customizacao.c_Larg).substring(0, String.valueOf(customizacao.c_Larg).indexOf('.'))
                                +'X'+String.valueOf(customizacao.c_Alt).substring(0, String.valueOf(customizacao.c_Alt).indexOf('.')) +' mm' : 
                            '';
                            String nomeProdutoCostumizacao = prod.refB +' - '+ customizacao.Local +' - '+ customizacao.Tecnica;
                            nomeProdutoCostumizacao = dimensoesMaximasImpressao != '' ? 
                                nomeProdutoCostumizacao +' - '+ dimensoesDeImpressaoDaComponente +' - '+ textoC : nomeProdutoCostumizacao +' - '+textoC;
                            customizacaoBuilder cBuilder = new customizacaoBuilder(cKey,i,prod.refB,nomeProdutoCostumizacao,customizacao.RefCust,customizacao.Compon,
                                                                                   customizacao.Tecnica,customizacao.merctabcust,dimensoesMaximasImpressao,
                                                                                   dimensoesDeImpressaoDaComponente,customizacao.c_Alt,customizacao.c_Larg,customizacao.Local,
                                                                                   customizacao.TabPers);
                            cBuilder.idA = customizacao.idA;
                            cBuilder.idT = customizacao.idT;
                            cBuilder.idL = customizacao.idL;
                            cBuilder.idC = customizacao.idC;
                            
                            cBuilder.costumizacaoToPBE.add(new customizacaoWrapper(customizacao));
                            mapCustomizacaoBuilder.put(cKey,cBuilder);
                        }else{
                            customizacaoBuilder cBuilder = mapCustomizacaoBuilder.get(cKey);
                            cBuilder.costumizacaoToPBE.add(new customizacaoWrapper(customizacao));
                            mapCustomizacaoBuilder.put(cKey,cBuilder);
                        }
                    }
                }
            }
        }
        //criar o produto customizacao
        for(String key : mapCustomizacaoBuilder.keySet()){
            customizacaoBuilder builder = mapCustomizacaoBuilder.get(key);
            Product2 sProd = new Product2();
            sProd.Name = builder.nomeProdutoCostumizacao;
            sProd.RecordTypeId = mapRTypes.get('Customizacao');
            sProd.isActive = true;
            sProd.ProductCode = builder.RefCustomizacao;
            sProd.Cores_de_customizacao__c = ''+builder.NumCol;
            sProd.ChaveExterna__c = key;
            sProd.Referencia_relacionada__c = builder.refRelacionada.contains('-') ? builder.refRelacionada.subString(0,builder.refRelacionada.indexOf('-')) : builder.refRelacionada;
            sProd.Tamanho__c = builder.refRelacionada.contains('-') ? builder.refRelacionada.subString(builder.refRelacionada.indexOf('-') + 1, builder.refRelacionada.length()) : '';
            sProd.Altura_maxima__c = builder.alturaMaxima;
            sProd.Comprimento_maximo__c = builder.compMaximo;
            sProd.Componente_da_impressao__c = builder.Componente;
            sProd.Tecnica__c = builder.Tecnica;
            sProd.Dimensoes_maximas_de_impressao__c = builder.dimensoesMaximasImpressao;
            sProd.Dimensoes_de_impressao_da_componente__c = builder.dimensoesDeImpressaoDaComponente;
            sProd.Localizacao_da_impressao__c = builder.localizacao;
            sProd.Tabela_de_customizacoes__c = builder.TabPers;
            
            //campos adicionados a 2018-09-11
            sProd.Id_Area__c = builder.idA;
            sProd.Id_Tecnica__c = builder.idT;
            sProd.Id_Local__c = builder.idL;
            sProd.Id_Componente__c = builder.idC;
            
            if(mapTraducoesCustom.containsKey(sProd.ProductCode)) runTraducoes(sProd, mapTraducoesCustom.get(sProd.ProductCode));
            produtosCustomizacaoToUpsert.add(sProd);
        }
        Database.UpsertResult[] srProdutos = DataBase.Upsert(produtosCustomizacaoToUpsert,Product2.ChaveExterna__c, false);
        
        String errors = '';
        //verificar se falhou algum produto
        for(Database.UpsertResult result :srProdutos){
            if(!result.isSuccess()){
                errors += result.getErrors() + '\r\n';
            }
        }
        if(errors != ''){
            UtilClaims.sendEmailFailure('Falha importação customiza:Customizações', errors);
        }
        
        //Criar os pricebookEntries dos produtos customizacoes
        Integer i = 0;
        for(String key : mapCustomizacaoBuilder.keySet()){
            customizacaoBuilder builder = mapCustomizacaoBuilder.get(key);
            builder.costumizacaoToPBE.sort();
            List<customizacaoWrapper> costumizacoes = builder.costumizacaoToPBE;
            
            //Cria mapa com lista de preços por mercado para uma dada costumização chave = mercado;
            Map<String,customizacaoBuilderMercado> mapCostumizacoesPorMercado = new Map<String,customizacaoBuilderMercado>();
            for(customizacaoWrapper wrapper : costumizacoes){
                if(!mapCostumizacoesPorMercado.containsKey(''+wrapper.customizacao.merctabcust)){
                    customizacaoBuilderMercado cBMerc = new customizacaoBuilderMercado(builder.NumCol,wrapper.customizacao.merctabcust,wrapper.customizacao.Adicional);
                    cBMerc.costumizacaoToPBE.add(wrapper);
                    mapCostumizacoesPorMercado.put(''+wrapper.customizacao.merctabcust,cBMerc);
                }else{
                    customizacaoBuilderMercado cBMerc = mapCostumizacoesPorMercado.get(''+wrapper.customizacao.merctabcust);
                    cBMerc.costumizacaoToPBE.add(wrapper);
                    mapCostumizacoesPorMercado.put(''+wrapper.customizacao.merctabcust,cBMerc);
                }       
            }
            for(String keyMerc : mapCostumizacoesPorMercado.keySet()){
                if(srProdutos[i].isSuccess()){
                    customizacaoBuilderMercado cBMerc = mapCostumizacoesPorMercado.get(keyMerc); 
                    cBMerc.costumizacaoToPBE.sort();
                    List<customizacaoWrapper> costumizacoesMerc = cBMerc.costumizacaoToPBE;
                    PricebookEntry pbe = defaultPBE();
                    if(srProdutos[i].isCreated()){
                        pbe.Product2Id = srProdutos[i].getId();
                        pbe.Pricebook2Id = mapPricebook.get(''+cBMerc.merctabcust);
                        pbe.CurrencyIsoCode = mapISOCodes.get(''+cBMerc.merctabcust);    
                    }
                    pbe.ChaveExterna__c = srProdutos[i].getId() +''+ mapPricebook.get(''+cBMerc.merctabcust)+''+mapISOCodes.get(''+cBMerc.merctabcust);
                    pbe.UseStandardPrice = false;
                    pbe.UnitPrice = 0;
                    pbe.IsActive = true;
                    pbe.Custo_adicional__c = cBMerc.CustoAdicional;
                    Integer posicaoPreco = 1;
                    Integer maxSize = costumizacoesMerc.size();
                    for(customizacaoWrapper wrapper : costumizacoesMerc){
                        atribuiPrecoQuant(pbe, posicaoPreco, wrapper, maxSize, cBMerc.NumCol);
                        ++posicaoPreco;
                    }
                    
                    pbCustomizacaoToUpsert.add(pbe);
                }
            }
            
            ++i;
        }
        
        
    }
    
    public static void atribuiPrecoQuant(PricebookEntry pbe, Integer posicaoPreco, customizacaoWrapper wrapper, Integer maxSize, Integer NumCol){
        try{
            if(posicaoPreco > 1){
                try{
                    //atribui maximo à categoria anterior
                    pbe.put('Maximo_' + (posicaoPreco - 1) + '__c', wrapper.customizacao.qt - 1);
                }catch(Exception ex){}
            }
            //quantidade minima é sempre a que vem na primeira camada
            pbe.put('Minimo_' + posicaoPreco + '__c', wrapper.customizacao.qt);
            
            //tenta por maximo caso não existam mais wrappers para percorrer
            pbe.put('Maximo_' + posicaoPreco + '__c', (maxSize == posicaoPreco ? 9999999 : null));
            
            //atribui o preço à camada correspondente
            pbe.put('Preco_'+ posicaoPreco + '__c', wrapper.getPrice(NumCol));            
        }catch(Exception ex2){
            //UtilClaims.sendEmailFailure('Falha na importação de produtos','Algo correu mal a importar produtos \n' + ex2.getMessage());
        }
    }
    
    private static void runTraducoes(Product2 prod, Traducao_Custom__mdt trad){
        prod.Nome_do_produto_PT_BR__c = trad.Descricao_PT__c;
        prod.Nome_do_produto_EN_US__c = trad.Descricao_EN_US__c;
        prod.Nome_do_produto_ES__c = trad.Descricao_ES__c;
        prod.Nome_do_produto_FR__c = trad.Descricao_FR__c;
        prod.Nome_do_produto_IT__c = trad.Descricao_IT__c;
        prod.Nome_do_produto_DE__c = trad.Descricao_DE__c;
        prod.Nome_do_produto_NL__c = trad.Descricao_NL_NL__c;
        prod.Nome_do_produto_PL__c = trad.Descricao_PL__c;
        prod.Nome_do_produto_RU__c = trad.Descricao_RU__c;
    }
    
    private static PricebookEntry defaultPBE(){
        return new PricebookEntry(Minimo_1__c = null,Maximo_1__c = null,Minimo_2__c = null,Maximo_2__c = null,Minimo_3__c = null,Maximo_3__c = null,Minimo_4__c = null,Maximo_4__c = null
                                 ,Minimo_5__c = null,Maximo_5__c = null,Minimo_6__c = null,Maximo_6__c = null,Minimo_7__c = null,Maximo_7__c = null,Minimo_8__c = null,Maximo_8__c = null
                                 ,Minimo_9__c = null,Maximo_9__c = null,Minimo_10__c = null,Maximo_10__c = null);
    }
    
    public class customizacaoBuilderMercado{
        
        public Integer NumCol {get;set;}
        public Integer merctabcust {get;set;}
        public Decimal CustoAdicional {get;set;}
        public List<customizacaoWrapper> costumizacaoToPBE {get;set;}
        
        public customizacaoBuilderMercado(Integer NumCol,Integer merctabcust,Decimal CustoAdicional){
            this.NumCol = NumCol;
            this.merctabcust = merctabcust;
            this.CustoAdicional = CustoAdicional;
            costumizacaoToPBE = new List<customizacaoWrapper>();
        }
    }
    public class customizacaoBuilder{
        
        public String cKey {get;set;}
        public Integer NumCol {get;set;}
        public String refRelacionada {get;set;}
        public String nomeProdutoCostumizacao {get;set;}
        public String RefCustomizacao {get;set;}
        public String Componente {get;set;}
        public String Tecnica {get;set;}
        public Integer merctabcust {get;set;}
        public String dimensoesMaximasImpressao {get;set;}
        public String dimensoesDeImpressaoDaComponente {get;set;}
        public Decimal alturaMaxima {get;set;}
        public Decimal compMaximo {get;set;}
        public String localizacao {get;set;}
        public String TabPers {get;set;}
        public List<customizacaoWrapper> costumizacaoToPBE {get;set;}
        public Integer idA {get;set;}
        public Integer idT {get;set;}
        public Integer idL {get;set;}
        public Integer idC {get;set;}
        
        public customizacaoBuilder(String cKey,Integer NumCol,String refRelacionada,String nomeProdutoCostumizacao,String RefCustomizacao,
                                   String Componente,String Tecnica,Integer merctabcust,String dimensoesMaximasImpressao,String dimensoesDeImpressaoDaComponente,
                                   Decimal alturaMaxima,Decimal compMaximo,String localizacao,String TabPers){
                                       
                                       this.cKey = cKey;
                                       this.NumCol = NumCol;
                                       this.refRelacionada = refRelacionada;
                                       this.nomeProdutoCostumizacao = nomeProdutoCostumizacao;
                                       this.RefCustomizacao = RefCustomizacao;
                                       this.Componente = Componente;
                                       this.Tecnica = Tecnica;
                                       this.merctabcust = merctabcust;
                                       this.dimensoesMaximasImpressao = dimensoesMaximasImpressao;
                                       this.dimensoesDeImpressaoDaComponente= dimensoesDeImpressaoDaComponente;
                                       this.alturaMaxima = alturaMaxima;
                                       this.compMaximo = compMaximo;
                                       this.localizacao = localizacao;
                                       this.TabPers = TabPers;
                                       costumizacaoToPBE = new List<customizacaoWrapper>();                            
                                   }            
    }
    
    global class customizacaoWrapper implements Comparable {
        public clientStricker.Customizacao customizacao;
        
        public customizacaoWrapper(clientStricker.Customizacao cust){
            this.customizacao = cust;       
        }
        
        global Integer compareTo(Object compareTo) {
            customizacaoWrapper compareToCust = (customizacaoWrapper)compareTo;
            Integer returnValue = 0;
            
            if(customizacao.qt > compareToCust.customizacao.qt){
                returnValue = 1;       
            }else if(customizacao.qt < compareToCust.customizacao.qt){
                returnValue = -1;   
            }
            return returnValue;
        }
        
        global Decimal getPrice(Integer i){
            if(i == 1){
                return customizacao.p1;
            }else if(i == 2){
                return customizacao.p2;
            }else if(i == 3){
                return customizacao.p3;
            }else if(i == 4){
                return customizacao.p4;
            }else if(i == 5){
                return customizacao.p5;
            }
            return 0;
        }
    }
}