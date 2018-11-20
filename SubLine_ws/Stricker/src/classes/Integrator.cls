public class Integrator {
    public static clientStricker.ClientStrickerSoap servico = new clientStricker.ClientStrickerSoap();
    public static wsdl_Contactos.ContactosPHCSoap servContacts = new wsdl_Contactos.ContactosPHCSoap();
    public static wsdl_Viewer.ViewerPHCSoap servViewer = new wsdl_Viewer.ViewerPHCSoap();

    @future(callout=true)
    public static void contactUpsert(Set<Id> objectsId){
        checkRecursive.runContact = false;
        
        Map<String, User> usersMap = new Map<String, User>([Select id, Codigo_de_utilizador__c, IsActive, Alias from User]);
        
        String query = 'SELECT '+Integrator.queryBuilder('Contact') + ', Id, Account.Name, Account.Numero_de_cliente__c';
        query += ' FROM Contact WHERE id IN :objectsId';
        
        List<Contact> contacts = Database.query(query);
        Integer i = 0;
        
        for(Contact contact : contacts){
            if(i < 100){
                wsdl_Contactos.ContactoPHC cont = new wsdl_Contactos.ContactoPHC();
                
                cont.numCliente = contact.Account.Numero_de_cliente__c.isNumeric() ? Integer.valueOf(contact.Account.Numero_de_cliente__c) : 0;
                cont.nome = contact.Account.Name != null ? contact.Account.Name : '';
                cont.contacto = contact.FirstName != null ? contact.FirstName : '';
                //cont.firstName = 
                cont.lastName = contact.LastName != null ? contact.LastName : '';
                cont.funcao = contact.Funcao__c != null ? contact.Funcao__c : '';
                cont.Email = contact.Email != null ? contact.Email : '';
                cont.Phone = contact.Phone != null ? contact.Phone : '';
                cont.MobilePhone = contact.MobilePhone != null ? contact.MobilePhone : '';
                cont.Fax = contact.Fax != null ? contact.Fax : '';
                cont.utilizadorLogado = usersMap.containsKey(UserInfo.getUserId()) ? usersMap.get(UserInfo.getUserId()).Alias : '';
                cont.IDSF = contact.Id != null ? contact.Id : '';
                cont.u_centraltelstamp = contact.Stamp__c != null ? contact.Stamp__c : '';
                
                wsdl_Contactos.stampUpSet resposta;
                resposta = servContacts.upSert_x(cont);
                
                contact.Stamp__c = resposta.stamp;
                i++;
            }else break;
        }
        update contacts;
    }
    
    @future(callout=true)
    public static void contactDelete(String objectsId){
        List<Integrator.DeleteContact> lista = (List<Integrator.DeleteContact>) JSON.deserialize(objectsId, List<Integrator.DeleteContact>.class);
        Integer i = 0;
        for(Integrator.DeleteContact contact : lista){
            if(i < 100){
                wsdl_Contactos.stampUpSet resposta;
                resposta= servContacts.delete_x(contact.stamp, contact.sfid);
                system.debug(resposta);
                i++;
            }else break;
        }
    }
    
    public class DeleteContact{
        public String stamp;
        public String sfid;
        
        public DeleteContact(String stamp,String sfid){
            this.stamp = stamp;
            this.sfid = sfid;
        }
    }
    
    public static clientStricker.ArrayOfContaCorrenteCliente consultaLstContaCorrente(Long nCliente){
        
        return servico.lstContaCorrenteCliente(nCliente);
    }
    
    public static clientStricker.ListaDocsFinanceirosPHC lstDocsFinanceiros(Integer pag){
        return servico.lstDocFinanceirosPHC(pag);
    }
    
    public static List<c_ViewerEncomendasCativar.Encomenda> encomendasPorCativar(String comercial){
        /*
        List<c_ViewerEncomendasCativar.Encomenda> encomendas = new List<c_ViewerEncomendasCativar.Encomenda>();
        clientStricker.ArrayOfEncomendasPorCativar result = servico.lstEncomendasPorCativar(comercial);
        
        if(result.EncomendasPorCativar != null){
            for(clientStricker.EncomendasPorCativar encomenda : result.EncomendasPorCativar){
                encomendas.add(new c_ViewerEncomendasCativar.Encomenda(encomenda.Descricao,encomenda.Comercial,encomenda.Referencia,encomenda.Quantidade,
                                                                       encomenda.Cativo,encomenda.NumDossier,encomenda.NumFolhaObra,encomenda.StockExistente));
            }
            
        }
        return encomendas;
		*/
        //RP
        List<c_ViewerEncomendasCativar.Encomenda> encomendas = new List<c_ViewerEncomendasCativar.Encomenda>();
        clientStricker.ArrayOfEncomendasPorCativar result = servico.lstEncomendasPorCativar(comercial);
        Map<String, c_ViewerEncomendasCativar.Encomenda> m_encomendas = new Map<String, c_ViewerEncomendasCativar.Encomenda>();
        if(result.EncomendasPorCativar != null){
            for(clientStricker.EncomendasPorCativar encomenda : result.EncomendasPorCativar){
                m_encomendas.put(encomenda.NumDossier, new c_ViewerEncomendasCativar.Encomenda(encomenda.Descricao,encomenda.Comercial,encomenda.Referencia,encomenda.Quantidade,
                                                                                                                            encomenda.Cativo,encomenda.NumDossier,encomenda.NumFolhaObra,encomenda.StockExistente));
            }
            List<Opportunity> l_opp = [Select id,Referencia_PHC__c From Opportunity where Referencia_PHC__c in :m_encomendas.keyset()];
            if(!l_opp.isEmpty()){
                for(Opportunity oppl :l_opp){
                    if(m_encomendas.containskey(oppl.Referencia_PHC__c)){
                        encomendas.add(m_encomendas.get(oppl.Referencia_PHC__c));
                    }
                }
            }
        }
        return encomendas;
    }
    
    public static void consultaStock(c_AddProduct.Product prod, String ref, String tamanho, String cor){
        system.debug(ref + tamanho + cor);
        if(cor == '0') cor = '';
        clientStricker.StockProduto result = servico.consultaStockProduto(ref, tamanho, cor);
        system.debug(result);
        prod.stockAtual = result.Stock_atual_xc;
        prod.stockCativo = result.Stock_cativo_xc;
        if(result.Stock_previsto_xc > Date.newInstance(1900, 1, 1)) prod.stockData = result.Stock_previsto_xc;
        prod.stockPrevisto = result.QTStock_previsto_xc;
        system.debug(prod);
    }
    
    public static void consultaClienteIN(Account client){
        
    }
    
    @future(callout=true)
    public static void criaDossier(Id oppId){
        
        Opportunity opp = getOpp(oppId);
        
        if(!opp.OpportunityLineItems.isEmpty()) criaDossierWork(opp);
        
    }
    
    public static boolean criaDossierWork(Opportunity opp){
        checkRecursive.runOpportunityAfterUpdate = false;
        Integrator.servico.timeout_x = 120000;
        boolean doBreak = false;
        User user = [Select Id, Codigo_de_Utilizador__c From User Where Id = :opp.OwnerId];
        /* Construir estrutura do pedido
        * dossierSF
        */
        clientStricker.DossierCabNovo dossierSF = new clientStricker.DossierCabNovo();
        dossierSF.Referencia_interna_c = opp.Referencia_interna__c != null ? opp.Referencia_interna__c : '';

        dossierSF.Numero_de_cliente_xc = opp.Account.Numero_de_cliente__c != null ? Decimal.valueOf(opp.Account.Numero_de_cliente__c) : null;

        dossierSF.ndos = opp.Codigo_de_dossier__c != null ? Decimal.valueOf(opp.Codigo_de_dossier__c) : 0;

        dossierSF.idSalesForceDossier = opp.Id;

        dossierSF.StageName = opp.StageName != null ? opp.StageName : '';

        dossierSF.Motivo_de_pendente_xc = opp.Motivo_de_pendente__c != null ? opp.Motivo_de_pendente__c : '';

        dossierSF.Autorizada_xc = opp.Autorizada__c != null ? opp.Autorizada__c : '';

        //dossierSF.CloseDate = opp.CloseDate != null ? opp.CloseDate : Date.newInstance(1900, 1, 1); RETIRADO 03-07-2018

        dossierSF.Estado_da_maquete_xc =opp.Estado_da_maquete__c != null ? opp.Estado_da_maquete__c : '';

        dossierSF.Email_para_envio_de_maquete_xc = opp.Email_para_envio_de_maquete__c != null ? opp.Email_para_envio_de_maquete__c : '';

        dossierSF.N_de_versao_de_maquete_aceite_xc = opp.N_de_versao_de_maquete_aceite__c != null ? String.valueOf(opp.N_de_versao_de_maquete_aceite__c) : '';

        dossierSF.Data_do_pedido_de_maquete_xc = opp.Data_do_pedido_de_maquete__c != null ? opp.Data_do_pedido_de_maquete__c : Date.newInstance(1900, 1, 1);

        dossierSF.Data_de_aprovacao_de_maquete_xc = opp.Data_de_aprovacao_de_maquete__c != null ? 
            opp.Data_de_aprovacao_de_maquete__c : Date.newInstance(1900, 1, 1);

        dossierSF.Data_limite_de_producao_xc = opp.Data_limite_de_producao__c != null ? opp.Data_limite_de_producao__c : Date.newInstance(1900, 1, 1);

        dossierSF.Documento_de_destino_xc = opp.Documento_de_destino__c != null ? opp.Documento_de_destino__c : '';

        dossierSF.CurrencyIsoCode = opp.CurrencyIsoCode != null ? opp.CurrencyIsoCode : '';

        dossierSF.Amostra_xc = opp.Amostra__c;

        dossierSF.Tipologia_de_faturacao_xc = opp.Account.Tipologia_de_facturacao__c != null ? opp.Account.Tipologia_de_facturacao__c : '';

        dossierSF.Telefone_logistico_xc = opp.Telefone_logistico__c != null ? opp.Telefone_logistico__c : '';

        dossierSF.Custo_de_transporte_Stricker_xc = opp.Custo_de_transporte_Stricker__c != null ? opp.Custo_de_transporte_Stricker__c : 0;

        dossierSF.Destino_de_impressao_xc = opp.Destino_de_impressao__c != null ? opp.Destino_de_impressao__c : '';
        dossierSF.Notas_de_Expedicao_xc = opp.Notas_de_expedicao__c != null ? opp.Notas_de_expedicao__c : '';
        dossierSF.codOwner = user.Codigo_de_utilizador__c != null ? Integer.valueOf(user.Codigo_de_utilizador__c) : 32;//A PEDIDO DO JOSÉ PORQUE ERA UMA PESSOA QUE JÁ NAO ESTAVA NA EMPRESA
        dossierSF.designer = opp.Designer__c != null ? opp.Designer__c : '';
        dossierSF.erros = 0;

        dossierSF.mensagemErro = '';

        //Campo adicionado a 19/12-2017
        dossierSF.AnoDossierRep = opp.Dossier_de_repeticao__c != null ? opp.Dossier_de_repeticao__c : ' ';
        
        // 2018/10/16 : passar o armazem na criação 
        dossierSF.Armazem_xc = opp.Armazem__c != null ? Decimal.valueOf(opp.Armazem__c) : 1;
        
        //listaLinhasDossier
        clientStricker.ArrayOfDossierLinha listaLinhasDossier = new clientStricker.ArrayOfDossierLinha();
        
        listaLinhasDossier.DossierLinha = new List<clientStricker.DossierLinha>();
        
        Map<String,OpportunityLineItem> linhasExistentes = new Map<String, OpportunityLineItem>();
        
        for(OpportunityLineItem oli : opp.OpportunityLineItems){
            clientStricker.DossierLinha newLinha = new clientStricker.DossierLinha();
            
            newLinha.StampLinha_c = oli.Stamp__c != null ? oli.Stamp__c : '';

            newLinha.IdSalesDossierLinha = oli.Id;

            newLinha.Referencia_SKU_xc = oli.Referencia_SKU__c != null ? oli.Referencia_SKU__c : '';

            String idiomaConta = opp.Idioma_para_documentos__c != null ? opp.Idioma_para_documentos__c : 'pt_BR';
            if(idiomaConta == 'nl_NL') idiomaConta = 'nl';
                
            newLinha.DesignacaoProduto = oli.Product2.get('Nome_do_produto_' + idiomaConta + '__c') != null ? 
                (String) oli.Product2.get('Nome_do_produto_' + idiomaConta + '__c') : 
            oli.Product2.Nome_do_produto_en_US__c != null ? oli.Product2.Nome_do_produto_en_US__c : '';
            
            if(newLinha.DesignacaoProduto == null || newLinha.DesignacaoProduto == ''){
                newLinha.DesignacaoProduto = oli.Product2.get('Nome_do_produto_' + idiomaConta + '_PHC__c') != null ? 
                    (String) oli.Product2.get('Nome_do_produto_' + idiomaConta + '_PHC__c') : 
                oli.Product2.Nome_do_produto_en_US_PHC__c != null ? oli.Product2.Nome_do_produto_en_US_PHC__c : 
                //ALTERADO A 14-02-2018 PARA CASO EN_US ESTEJA A VAZIO MANDA PT
                oli.Product2.Nome_do_produto_pt_BR_PHC__c != null ? oli.Product2.Nome_do_produto_pt_BR_PHC__c : '';
            }
            
            newLinha.Texto_a_customizar_xc = oli.Texto_a_customizar__c != null ? oli.Texto_a_customizar__c : '';

            newLinha.Fonte_xc = oli.Fonte__c != null ? oli.Fonte__c : '';

            newLinha.Alinhamento_xc = oli.Alinhamento__c != null ? Decimal.valueOf(oli.Alinhamento__c) : 0;

            newLinha.Quantity = oli.Quantity != null ? oli.Quantity : 0;

            newLinha.TotalPrice = oli.TotalPrice != null ? oli.TotalPrice : 0;

            newLinha.Preco_unitario_xc = oli.Preco_unitario__c != null ? oli.Preco_unitario__c : oli.UnitPrice;

            newLinha.NomeCliente_contacto = '';

            newLinha.aoCuidadoDe = '';
            
            newLinha.numSeqMorada = 0;

            newLinha.MoradaEntrega = '';

            newLinha.CodPostalMoradaEntrega = '';

            newLinha.LocalidadeMoradaEntrega = '';

            newLinha.CodPaisMoradaEntrega = '';

            newLinha.NomePaisMoradaEntrega = '';

            newLinha.Altura_xc = oli.Altura__c != null ? oli.Altura__c : 0;

            newLinha.Componente_da_impressao_xc = oli.Componente_da_impressao__c != null ? oli.Componente_da_impressao__c : '';

            newLinha.Comprimento_xc = oli.Comprimento__c != null ? oli.Comprimento__c : 0;

            newLinha.Cores_customizacao = oli.Cores_de_customizacao__c != null ? oli.Cores_de_customizacao__c : '';

            newLinha.Numero_de_impressoes_xc = oli.Numero_de_impressoes__c != null ? oli.Numero_de_impressoes__c : 0;

            newLinha.Numero_de_repeticoes_xc = oli.Numero_de_repeticoes__c != null ? oli.Numero_de_repeticoes__c : 0;

            newLinha.Tecnica_xc = oli.Tecnica__c != null ? oli.Tecnica__c : '';

            newLinha.Transportadora_xc = oli.Expedicao__r.Transportadora__c != null ? oli.Expedicao__r.Transportadora__c : '';

            newLinha.Stock_cativo_xc = oli.Stock_cativo__c;

            newLinha.Telefone_logistico = opp.Telefone_logistico__c != null ? opp.Telefone_logistico__c : '';

            newLinha.Volume_xc = oli.Volume__c != null ? oli.Volume__c : 0;

            newLinha.Peso_xc = oli.Peso__c != null ? oli.Peso__c : 0;

            newLinha.Lotes_xc = '';

            newLinha.BIArmazem = 0;

            newLinha.Referencia_relacionada_xc = oli.Product2.Referencia_Relacionada__c != null ? oli.Product2.Referencia_Relacionada__c : '';
            newLinha.Pantone_cor_xc = oli.Pantone_cor__c != null ? oli.Pantone_cor__c : '';
            newLinha.localizaImpressao = oli.Localizacao_de_impressao__c != null ? oli.Localizacao_de_impressao__c : ' ';
            newLinha.tabImp = oli.Product2.Tabela_de_customizacoes__c != null ? oli.Product2.Tabela_de_customizacoes__c : '';
            newLinha.valorTabela = oli.Valor_de_tabela_de_precos__c;
            system.debug(newLinha);
            
            // novos campos linha 2018/06/28 
            newLinha.pEscalaoA = oli.Escalao_A__c != null ? oli.Escalao_A__c : 0;
            newLinha.pEscOriginal = oli.Valor_unitario_original__c != null ? oli.Valor_unitario_original__c : 0;
            
            
            listaLinhasDossier.DossierLinha.add(newLinha);
            //RESET ALOCACAO DE STOCK/Quantidade
            oli.Alocacao_de_Stock__c = '';
            oli.Quantity = 0;
            oli.Peso__c = 0;
            oli.Volume__c = 0;
            oli.Total_de_customizacao__c = 0;
            linhasExistentes.put(oli.Id, oli);
        }
        dossierSF.listaLinhasDossier = listaLinhasDossier;
        
        //**********************************************PEDIDO AO SERVIÇO*********************************************************//
        String utilizadorLogado = [Select id, Alias From User Where Id = :UserInfo.getUserId()].Alias;//'AS'
        /*if(utilizadorLogado == 'guest'){
            utilizadorLogado = 'SF Site Cli ' + opp.Account.Numero_de_cliente__c;
        }*/

        system.debug(dossierSF);
        try{
           doBreak = trataRespostaDossier(servico.criaDossierPHC(dossierSF, utilizadorLogado), opp, linhasExistentes);
        }catch(Exception ex){
            doBreak = true;
            UtilClaims.sendEmailFailure('Falha criação dossier', 'Dossier: ' + opp + '\r\nException thrown: ' + ex.getMessage() + '\r\nLinha: ' + ex.getLineNumber());
            System.debug(LoggingLevel.INFO, ex.getMessage() +' ' + ex.getLineNumber());
            opp = [Select Id, Description from Opportunity Where Id = :opp.Id];
            opp.Description = opp.Description != null ? opp.Description + '\n' + System.now().format() + ': ' + ex.getMessage() + ' ;' +' ' + ex.getLineNumber() : System.now().format() + ': ' + ex.getMessage() +' ' + ex.getLineNumber();
            opp.Erro_comunicacao__c = true;
            update opp;
        }
        
        return doBreak;
    }
    
    public class ServiceException extends Exception{}
    
    @future(callout=true)
    public static void actDossier(Set<Id> oppIds){
        for(Id oppId : oppIds){
            actDossierDoWork(getOpp(oppId), true);
        }
    }
    
    //Keidy - novo metodo para receber o mexeLinhas como parametro (usando o polimorfismo).
    @future(callout=true)
    public static void actDossier(Set<Id> oppIds, Boolean mexeLinhas){
        for(Id oppId : oppIds){
            actDossierDoWork(getOpp(oppId), mexeLinhas);
        }
    }
    
    public static boolean actDossierDoWork(Opportunity opp, Boolean mexeLinhas /*Keidy - parametro para controlo do mexeLinhas*/){
        checkRecursive.runOpportunityAfterUpdate = false;
        Integrator.servico.timeout_x = 120000;
        boolean doBreak = false;
        
        clientStricker.DossierCabACT dossierSF = new clientStricker.DossierCabACT();
        dossierSF.idSalesForceDossier = opp.Id;
        dossierSF.Stamp_xc = opp.Stamp__c != null ? opp.Stamp__c : '';
        dossierSF.Referencia_interna_c = opp.Referencia_interna__c != null ? opp.Referencia_interna__c : '';
        dossierSF.Numero_de_cliente_xc = opp.Account.Numero_de_cliente__c != null ? Decimal.valueOf(opp.Account.Numero_de_cliente__c) : 0;
       // 2018/08/22  dossierSF.StageName = opp.StageName != null ? (opp.Estado_da_maquete__c != 'Em aprovação do cliente' ? opp.StageName : 'Aprovação') : '';
        dossierSF.StageName = opp.StageName != null ?  opp.StageName  : '';
        dossierSF.Motivo_de_pendente_xc = opp.Motivo_de_pendente__c != null ? opp.Motivo_de_pendente__c : '';
        dossierSF.Autorizada_xc = opp.Autorizada__c != null ? opp.Autorizada__c : '';
        //dossierSF.CloseDate = opp.CloseDate != null ? opp.CloseDate : Date.newInstance(1900, 1, 1); RETIRADO 03-07-2018
        dossierSF.Estado_da_maquete_xc =opp.Estado_da_maquete__c != null ? opp.Estado_da_maquete__c : '';
        dossierSF.Email_para_envio_de_maquete_xc = opp.Email_para_envio_de_maquete__c != null ? opp.Email_para_envio_de_maquete__c : '';
        dossierSF.N_de_versao_de_maquete_aceite_xc = opp.N_de_versao_de_maquete_aceite__c != null ? String.valueOf(opp.N_de_versao_de_maquete_aceite__c) : '';
        dossierSF.Data_do_pedido_de_maquete_xc = opp.Data_do_pedido_de_maquete__c != null ? opp.Data_do_pedido_de_maquete__c : Date.newInstance(1900, 1, 1);
        dossierSF.Data_de_aprovacao_de_maquete_xc = opp.Data_de_aprovacao_de_maquete__c != null ? opp.Data_de_aprovacao_de_maquete__c : Date.newInstance(1900, 1, 1);
        dossierSF.Data_limite_de_producao_xc = opp.Data_limite_de_producao__c != null ? opp.Data_limite_de_producao__c : Date.newInstance(1900, 1, 1);
        dossierSF.Documento_de_destino_xc = opp.Documento_de_destino__c != null ? opp.Documento_de_destino__c : '';
        dossierSF.Amostra_xc = opp.Amostra__c;
        dossierSF.Custo_de_transporte_Stricker_xc = opp.Custo_de_transporte_Stricker__c != null ? opp.Custo_de_transporte_Stricker__c : 0;
        dossierSF.Destino_de_impressao_xc = opp.Destino_de_impressao__c != null ? opp.Destino_de_impressao__c : '';
        dossierSF.Notas_de_Expedicao_xc = opp.Notas_de_expedicao__c != null ? opp.Notas_de_expedicao__c : '';
        dossierSF.Armazem_xc = opp.Armazem__c != null ? Decimal.valueOf(opp.Armazem__c) : 1;
        dossierSF.erros = 0;
        dossierSF.mensagemErro = '';
        dossierSF.AnoDossierRep = opp.Dossier_de_repeticao__c != null ? opp.Dossier_de_repeticao__c : ' ';
        dossierSF.dataEnvioMaq = opp.Data_de_envio_de_maquete__c != null ? opp.Data_de_envio_de_maquete__c : Date.newInstance(1900, 1, 1);
        dossierSF.dataEnvio = opp.Data_de_envio__c != null ? opp.Data_de_envio__c : Date.newInstance(1900, 1, 1);
        dossierSF.versaoMaqEnv =  opp.Versao_de_Maquete_Enviada__c != null ? opp.Versao_de_Maquete_Enviada__c : 0;
        dossierSF.designer = opp.Designer__c != null ? opp.Designer__c : '';
        dossierSF.logi4 = opp.Nao_calcula_portes_automaticos__c;
        //RP a versao passou para antes do future
        /*
        if(opp.Versao_enviada__c != null){
            opp.Versao_enviada__c = opp.Versao_enviada__c + 1;
        }else{
            opp.Versao_enviada__c = 1;
        }
		*/
        dossierSF.nversao = opp.Versao_enviada__c != null ? opp.Versao_enviada__c: 1;
        
        //Keidy - Acrescentou-se a ação 'Autorizar' para o Administrador 
        dossierSF.dirComercial = false;
        for(Profile_Id__mdt pi :[Select Id__c From Profile_Id__mdt Where DeveloperName = 'Director_Comercial' OR DeveloperName = 'Administrador_do_sistema']){
            if(pi.Id__c.contains(UserInfo.getProfileId())){
                dossierSF.dirComercial = true;
                break;
            }
        }
        //dossierSF.dirComercial = [Select Id__c From Profile_Id__mdt Where DeveloperName = 'Director_Comercial'].Id__c.contains(UserInfo.getProfileId());
        
        
        //TODO 2018/10/30: mandar valores no mexeLinha 
        // 
        dossierSF.mexeLinhas = mexeLinhas; 
        
        
        /*listaLinhasDossier*/
        clientStricker.ArrayOfDossierLinha listaLinhasDossier = new clientStricker.ArrayOfDossierLinha();
        
        listaLinhasDossier.DossierLinha = new List<clientStricker.DossierLinha>();
        
        Map<String,OpportunityLineItem> linhasExistentes = new Map<String, OpportunityLineItem>();
        
        for(OpportunityLineItem oli : opp.OpportunityLineItems){
            clientStricker.DossierLinha newLinha = new clientStricker.DossierLinha();
            
            newLinha.StampLinha_c = oli.Stamp__c != null ? oli.Stamp__c : '';
            newLinha.IdSalesDossierLinha = oli.Id;
            
            if(oli.Codigo_de_cor__c != null ? oli.Referencia_SKU__c.contains(oli.Codigo_de_cor__c) : true){
                newLinha.Referencia_SKU_xc = oli.Referencia_SKU__c != null ? oli.Referencia_SKU__c : '';
            }else{
                newLinha.Referencia_SKU_xc = oli.Referencia_SKU__c != null ? oli.Referencia_SKU__c + '.' + oli.Codigo_de_cor__c : '';
                oli.Referencia_SKU__c = newLinha.Referencia_SKU_xc;
            }
            
            
            String idiomaConta = opp.Idioma_para_documentos__c != null ? opp.Idioma_para_documentos__c : 'pt_BR';
            if(idiomaConta == 'nl_NL') idiomaConta = 'nl';
            /*Alterado a 15/01/2018 por have produtos (customizações) sem designações
             * newLinha.DesignacaoProduto = oli.Product2.get('Nome_do_produto_' + idiomaConta + '__c') != null ? 
                (String) oli.Product2.get('Nome_do_produto_' + idiomaConta + '__c') : 
            oli.Product2.Nome_do_produto_en_US__c != null ? oli.Product2.Nome_do_produto_en_US__c : oli.Product2.Nome_do_produto_pt_BR__c;*/
            
            newLinha.DesignacaoProduto = oli.Product2.get('Nome_do_produto_' + idiomaConta + '__c') != null ? 
                (String) oli.Product2.get('Nome_do_produto_' + idiomaConta + '__c') : 
            oli.Product2.Nome_do_produto_en_US__c != null ? oli.Product2.Nome_do_produto_en_US__c : '';
            
            if(newLinha.DesignacaoProduto == null || newLinha.DesignacaoProduto == ''){
                newLinha.DesignacaoProduto = oli.Product2.get('Nome_do_produto_' + idiomaConta + '_PHC__c') != null ? 
                    (String) oli.Product2.get('Nome_do_produto_' + idiomaConta + '_PHC__c') : 
                oli.Product2.Nome_do_produto_en_US_PHC__c != null ? oli.Product2.Nome_do_produto_en_US_PHC__c :
                //ALTERADO A 14-02-2018 PARA CASO EN_US ESTEJA A VAZIO MANDA PT
                oli.Product2.Nome_do_produto_pt_BR_PHC__c != null ? oli.Product2.Nome_do_produto_pt_BR_PHC__c : '';
            }
            
            newLinha.Texto_a_customizar_xc = oli.Texto_a_customizar__c != null ? oli.Texto_a_customizar__c : '';
            newLinha.Fonte_xc = oli.Fonte__c != null ? oli.Fonte__c : '';
            newLinha.Alinhamento_xc = oli.Alinhamento__c != null ? Decimal.valueOf(oli.Alinhamento__c) : 0;
            newLinha.Quantity = oli.Quantity != null ? oli.Quantity : 0;
            newLinha.TotalPrice = oli.TotalPrice != null ? oli.TotalPrice : 0;
            newLinha.Preco_unitario_xc = oli.Preco_unitario__c != null ? oli.Preco_unitario__c : oli.UnitPrice;
            newLinha.NomeCliente_contacto =  (oli.Expedicao__r.Morada_de_Entrega__r.Nome_da_empresa__c != null ? 
                                              oli.Expedicao__r.Morada_de_Entrega__r.Nome_da_empresa__c: opp.Account.Name);
            newLinha.aoCuidadoDe = oli.Expedicao__r.Morada_de_Entrega__r.Ao_Cuidado_De__c != null ? oli.Expedicao__r.Morada_de_Entrega__r.Ao_Cuidado_De__c : '';
            newLinha.Referencia_relacionada_xc = oli.Product2.Referencia_Relacionada__c != null ? oli.Product2.Referencia_Relacionada__c : '';
            newLinha.Pantone_cor_xc = oli.Pantone_cor__c != null ? oli.Pantone_cor__c : '';
            
            newLinha.localizaImpressao = oli.Localizacao_de_impressao__c != null ? oli.Localizacao_de_impressao__c : ' ';
            
            newLinha.numSeqMorada = oli.Expedicao__r.Morada_de_Entrega__r.MSEQ__c != null ? oli.Expedicao__r.Morada_de_Entrega__r.MSEQ__c : 0;
            newLinha.MoradaEntrega = oli.Expedicao__r.Morada_de_entrega__r.Morada_de_entrega__c != null ? oli.Expedicao__r.Morada_de_entrega__r.Morada_de_entrega__c : '';
            newLinha.CodPostalMoradaEntrega = oli.Expedicao__r.Morada_de_Entrega__r.Codigo_postal__c != null ?
                oli.Expedicao__r.Morada_de_Entrega__r.Codigo_postal__c : '';
            newLinha.LocalidadeMoradaEntrega = oli.Expedicao__r.Morada_de_Entrega__r.Localidade__c != null ?
                oli.Expedicao__r.Morada_de_Entrega__r.Localidade__c : '';
            newLinha.CodPaisMoradaEntrega = oli.Expedicao__r.Morada_de_Entrega__r.Pais__c != null ? oli.Expedicao__r.Morada_de_Entrega__r.Pais__c : '';
            String pais = '';
            if(oli.Expedicao__r.Morada_de_Entrega__r.Pais__c != null){
                Schema.DescribeFieldResult fieldResult = Morada_de_Entrega__c.Pais__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for( Schema.PicklistEntry f : ple){
                    if(f.getValue() == oli.Expedicao__r.Morada_de_Entrega__r.Pais__c){
                        pais = f.getLabel();
                        break;
                    }
                }
            }
            newLinha.NomePaisMoradaEntrega = pais;
            
            newLinha.Altura_xc = oli.Altura__c != null ? oli.Altura__c : 0;
            newLinha.Componente_da_impressao_xc = oli.Componente_da_impressao__c != null ? oli.Componente_da_impressao__c : '';
            newLinha.Comprimento_xc = oli.Comprimento__c != null ? oli.Comprimento__c : 0;
            newLinha.Cores_customizacao = oli.Cores_de_customizacao__c != null ? oli.Cores_de_customizacao__c : '';
            newLinha.Numero_de_impressoes_xc = oli.Numero_de_impressoes__c != null ? oli.Numero_de_impressoes__c : 0;
            newLinha.Numero_de_repeticoes_xc = oli.Numero_de_repeticoes__c != null ? oli.Numero_de_repeticoes__c : 0;
            newLinha.Tecnica_xc = oli.Tecnica__c != null ? oli.Tecnica__c : '';
            newLinha.Transportadora_xc = oli.Expedicao__r.Transportadora__c != null ? (oli.Expedicao__r.Recolha_do_cliente__c ? 'RECOLHA CLIENTE' : oli.Expedicao__r.Transportadora__c.toUpperCase()) : '';
            newLinha.Stock_cativo_xc = oli.Stock_cativo__c;
            newLinha.Telefone_logistico = opp.Telefone_logistico__c != null ? opp.Telefone_logistico__c : '';
            newLinha.Volume_xc = oli.Volume__c != null ? oli.Volume__c : 0;
            newLinha.Peso_xc = oli.Peso__c != null ? oli.Peso__c : 0;
            newLinha.Lotes_xc = '';
            newLinha.BIArmazem = 0;
            newLinha.tabImp = oli.Product2.Tabela_de_customizacoes__c != null ? oli.Product2.Tabela_de_customizacoes__c : '';
            // novos campos linha 2018/06/28 
            newLinha.pEscalaoA = oli.Escalao_A__c != null ? oli.Escalao_A__c : 0;
            newLinha.pEscOriginal = oli.Valor_unitario_original__c != null ? oli.Valor_unitario_original__c : 0;
            newLinha.valorTabela = oli.Valor_de_tabela_de_precos__c;
            system.debug(newLinha);
            listaLinhasDossier.DossierLinha.add(newLinha);
            
            //RESET ALOCACAO DE STOCK/Quantidade
            oli.Alocacao_de_Stock__c = '';
            oli.Peso__c = 0;
            oli.Quantity = 0;
            oli.Volume__c = 0;
            oli.Total_de_customizacao__c = 0;
            linhasExistentes.put(oli.Id, oli);
        }
        dossierSF.listaLinhasDossier = listaLinhasDossier;
        
        //**********************************************PEDIDO AO SERVIÇO*********************************************************//
        String utilizadorLogado = [Select id, Alias From User Where Id = :UserInfo.getUserId()].Alias;//'AS'
        system.debug(dossierSF);
        try{
            Atribuicao_zona_config__mdt fifo = [Select Id, Ativo__c From Atribuicao_zona_config__mdt Where DeveloperName = 'FIFO'];
            Boolean isFifo = fifo.Ativo__c && !Test.isRunningTest();
            if(isFifo){
                String sessionId = UserInfo.getSessionId() != null && UserInfo.getSessionId() != '' ? UserInfo.getSessionId() : '';
                doBreak = trataRespostaDossierFIFO(servico.actDossierFIFO(dossierSF, utilizadorLogado, sessionId), opp);
            }else{
                doBreak = trataRespostaDossier(servico.actualizaDossierPHC(dossierSF, utilizadorLogado), opp, linhasExistentes);
            }
        }catch(Exception ex){
            doBreak = true;
            System.debug(LoggingLevel.INFO, ex.getMessage()+' ' + ex.getLineNumber());
            UtilClaims.sendEmailFailure('Falha update dossier', 'Dossier: ' + opp + '\r\nException thrown: ' + ex.getMessage() + '\r\nLinha: ' + ex.getLineNumber() + '\r\nStack trace: ' + ex.getStackTraceString());
            opp = [Select Id, Description, Versao_enviada__c from Opportunity Where Id = :opp.Id];
            opp.Description = opp.Description != null ? opp.Description + '\n' + System.now().format() + ': ' + ex.getMessage() : System.now().format() + ': ' + ex.getMessage()+' ' + ex.getLineNumber();
            opp.Espera_de_integracao__c = false;
            opp.Versao_enviada__c = opp.Versao_enviada__c != null ? opp.Versao_enviada__c + 1 : 1;
            opp.Erro_comunicacao__c = true;
            update opp;
        }
        return doBreak;
    }
    
    public static boolean trataRespostaDossier(clientStricker.DossierRetorno result, Opportunity opp, Map<String, OpportunityLineItem> linhasExistentes){
        Map<Id, OpportunityLineItem> newOlis = new Map<Id, OpportunityLineItem>();
        Map<Id, OpportunityLineItem> listOli = new Map<Id,OpportunityLineItem>();
        Map<Id, List<OpportunityLineItem>> auxIds = new Map<Id, List<OpportunityLineItem>>();
        
        Datetime nullDate = Datetime.newInstance(2000, 1, 1);
        Datetime errorDate = Datetime.newInstance(1, 1, 1);
        boolean doBreak = false;
        system.debug(result);
        if(result.erros == -99){//erro de dossier já criado
            system.debug('Dossier já criado');
            opp = getOpp(opp.Id);
            opp.Stamp__c = result.Stamp_xc;
            //Keidy - acrescentei mais um parametro no metodo.
           return actDossierDoWork(opp, true);
        }else{
            /*************************************************************************************************************************************************************************/
            /*************************************************************************************************************************************************************************/
            /****************************APENAS TRATA A RESPOSTA SE O DOSSIER AINDA NÃO ESTIVER AUTORIZADO OU A OPERAÇÃO VIER DE UM SUPER USER****************************************/
            /*************************************************************************************************************************************************************************/
            /*************************************************************************************************************************************************************************/
            system.debug(LoggingLevel.INFO, 'Validar se trata resposta');
            String autorizada = [Select Autorizada__c From Opportunity Where Id =:opp.Id].Autorizada__c;
            if((autorizada == '' || autorizada == null) || (opp.Autorizada__c != '' && userInfo.getProfileId() == [Select Id__c from Profile_Id__mdt Where DeveloperName = 'Administrador_do_sistema'].Id__c)) {
                system.debug(LoggingLevel.INFO, 'A tratar resposta');
                
                //***************************************************TRATAMENTO DA RESPOSTA*************************************************
                Map<Id, Expedicao__c> expedicoes = new Map<Id, Expedicao__c>();
                
                Map<Id,OpportunityLineItem> customs = new Map<Id, OpportunityLineItem>();
                Set<String> newCodes = new Set<String>();
                Set<String> newSizes = new Set<String>();
                List<TempOli> tempList = new List<TempOli>();
                
                if(result.listaLinhasDossiers != null && result.listaLinhasDossiers.DossierLinha != null){
                    for(clientStricker.DossierLinha linha : result.listaLinhasDossiers.DossierLinha){
                        OpportunityLineItem item;
                        system.debug(linha);
                        //Se a linha tiver Id SF
                        if(linha.IdSalesDossierLinha != ''){
                            
                            item = linhasExistentes.containsKey(linha.IdSalesDossierLinha)
                                ? linhasExistentes.get(linha.IdSalesDossierLinha).clone() : new OpportunityLineItem();
                            
                            /*verifica se a linha da resposta tem stock cativo e se a linha original tem stock cativo
                            * se não tiver igual, significa que a linha terá de ser partida, ou que houve cativação de stock numa linha não cativa
                            */
                                                
                            if(Test.isRunningTest() || (item.Product2Id != null && item.Product2.RecordType.DeveloperName == 'Produto')){
                                
                                if(item.Stock_cativo__c != linha.Stock_cativo_xc){
                                    doBreak = true;
                                    system.debug('vai partir linha;');
                                    if(linha.Stock_cativo_xc){
                                       	if(linhasExistentes.containsKey(item.Id_Original__c)){
                                            linhasExistentes.get(item.Id_Original__c).Quantity += linha.Quantity;
                                        }
                                        customs.put(linha.IdSalesDossierLinha, linhasExistentes.get(item.Id_Original__c));
                                        if(linha.Lotes_xc != '' && linhasExistentes.containsKey(item.Id_Original__c)){
                                            linha.Lotes_xc = linha.Lotes_xc == null ? '' : linha.Lotes_xc;
                                            linhasExistentes.get(item.Id_Original__c).Alocacao_de_Stock__c +=
                                                linha.BIArmazem + ' - ' + String.valueOf(linha.Lotes_xc) + ' - ' + linha.Quantity + ';\r\n';
                                        }
                                        item.Id = item.Id_Original__c;
                                        item.Total_de_customizacao__c = linha.TotalPrice;
                                        if(linhasExistentes.containsKey(item.Id_Original__c)) item.Quantity += linhasExistentes.get(item.Id_Original__c).Quantity;
                                    }else{
                                        item.Id_Original__c = linha.IdSalesDossierLinha;
                                        if(linha.Lotes_xc != ''){
                                            item.Alocacao_de_Stock__c = linha.BIArmazem + ' - ' + String.valueOf(linha.Lotes_xc) + ' - ' + linha.Quantity + ';\r\n';
                                        }else{
                                            item.Alocacao_de_Stock__c = Label.Em_Falta + ' - ' + linha.Quantity + ';\r\n';
                                            //RP
                                            //item.Peso__c =  Double.valueOf((Double.valueOf(item.Product2.Peso_caixa__c) / Double.valueOf(item.Product2.Caixa_interior_unidades__c)) * item.quantity);
                                        }
                                        item.Quantity = linha.Quantity;
                                        item.Total_de_customizacao__c = linha.TotalPrice;
                                        customs.put(linha.IdSalesDossierLinha, linhasExistentes.get(linha.IdSalesDossierLinha));
                                        newOlis.put(item.Id_Original__c ,item);
                                    }
                                }else{
                                    system.debug('mesma linha somar stock;');
                                    item.Id = linha.IdSalesDossierLinha;
                                    item.Quantity += linha.Quantity;
                                    if(linha.Peso_xc != null) item.Peso__c = item.Peso__c != null ? item.Peso__c + linha.Peso_xc : linha.Peso_xc;
                                    if(linha.Volume_xc != null) item.Volume__c = item.Volume__c != null ? item.Volume__c + linha.Volume_xc : linha.Volume_xc;
                                    if(linha.TotalPrice != null) item.Total_de_customizacao__c = item.Total_de_customizacao__c != null ? item.Total_de_customizacao__c
                                        + linha.TotalPrice : linha.TotalPrice;
                                    if(item.Product2.RecordType.DeveloperName == 'Produto'){
                                        if(linha.Lotes_xc != ''){
                                            item.Alocacao_de_Stock__c += (item.Alocacao_de_Stock__c == '' ? '' : '\r\n')
                                                + linha.BIArmazem + ' - ' 
                                                + (linha.Lotes_xc != '' ? String.valueOf(linha.Lotes_xc) + ' - ' : '')
                                                + linha.Quantity + ';';
                                        }else if(!linha.Stock_cativo_xc){
                                            item.Alocacao_de_Stock__c += Label.Em_Falta + ' - ' + linha.Quantity + ';';
                                            //RP
                                            //item.Peso__c =  Double.valueOf((Double.valueOf(item.Product2.Peso_caixa__c) / Double.valueOf(item.Product2.Caixa_interior_unidades__c)) * item.quantity);
                                        }
                                    }
                                    linhasExistentes.put(linha.IdSalesDossierLinha, item);
                                }
                                if(linha.StampLinha_c != null && item.Stamp__c != linha.StampLinha_c.trim()) item.Stamp__c = linha.StampLinha_c;
                                
                                if(linha.DesignacaoProduto != null) item.Description = linha.DesignacaoProduto;
                                if(linha.Preco_unitario_xc != null) item.Preco_unitario__c = linha.Preco_unitario_xc;
                                if(linha.Altura_xc != null) item.Altura__c = linha.Altura_xc;
                                if(linha.Componente_da_impressao_xc != null && linha.Componente_da_impressao_xc != '-') 
                                    item.Componente_da_impressao__c = linha.Componente_da_impressao_xc;
                                if(linha.Comprimento_xc != null) item.Comprimento__c = linha.Comprimento_xc;
                                if(linha.Cores_customizacao != null && linha.Cores_customizacao != '-' && linha.Cores_customizacao != '0') item.Cores_de_customizacao__c = linha.Cores_customizacao;
                                if(linha.Numero_de_impressoes_xc != null) item.Numero_de_impressoes__c = linha.Numero_de_impressoes_xc;
                                if(linha.Numero_de_repeticoes_xc != null) item.Numero_de_repeticoes__c = linha.Numero_de_repeticoes_xc;
                                if(linha.Tecnica_xc != null && linha.Tecnica_xc != '-') item.Tecnica__c = linha.Tecnica_xc;
                                if(linha.Stock_cativo_xc != null) item.Stock_cativo__c = linha.Stock_cativo_xc;
                                if(linha.Telefone_logistico != null && item.Expedicao__c != null)
                                    expedicoes.put(item.Expedicao__c, new Expedicao__c(Id = item.Expedicao__c, Telefone_Logistico__c = linha.Telefone_logistico));
                                if(item.Id == null)item.TotalPrice = null;
                                system.debug(item.TotalPrice);
                                if(item.Id != null) listOli.put(item.Id, item);
                                else newOlis.put(item.Id_Original__c ,item);
                            }
                        }else{//linha nova
                            item = new OpportunityLineItem();
                            
                            item.OpportunityId = opp.Id;
                            if(linha.Peso_xc != null) item.Peso__c = linha.Peso_xc;
                            if(linha.Lotes_xc != null) item.Alocacao_de_Stock__c = linha.BIArmazem + ' - ' 
                                + (String.valueOf(linha.Lotes_xc) != 'Em Falta' ? String.valueOf(linha.Lotes_xc) : Label.Em_Falta)
                                + ' - ' + linha.Quantity;
                            item.Quantity = linha.Quantity;
                            if(linha.Volume_xc != null) item.Volume__c = linha.Volume_xc;
                            if(linha.TotalPrice != null) item.Total_de_customizacao__c = linha.TotalPrice;
                            if(linha.StampLinha_c != null) item.Stamp__c = linha.StampLinha_c;
                            if(linha.Referencia_SKU_xc != null) item.Referencia_SKU__c = linha.Referencia_SKU_xc;
                            if(linha.DesignacaoProduto != null) item.Description = linha.DesignacaoProduto;
                            if(linha.Texto_a_customizar_xc != null && linha.Texto_a_customizar_xc != '-') item.Texto_a_customizar__c = linha.Texto_a_customizar_xc;
                            if(linha.Fonte_xc != null && linha.Fonte_xc != '-') item.Fonte__c = linha.Fonte_xc;
                            if(linha.Alinhamento_xc != null) item.Alinhamento__c = String.valueOf((Integer)linha.Alinhamento_xc);
                            if(linha.Preco_unitario_xc != null) {
                                item.Preco_unitario__c = linha.Preco_unitario_xc;
                                item.UnitPrice = linha.Preco_unitario_xc;
                            }
                            
                            if(linha.Altura_xc != null) item.Altura__c = linha.Altura_xc;
                            if(linha.Componente_da_impressao_xc != null && linha.Componente_da_impressao_xc != '-') 
                                item.Componente_da_impressao__c = linha.Componente_da_impressao_xc;
                            if(linha.Comprimento_xc != null) item.Comprimento__c = linha.Comprimento_xc;
                            if(linha.Cores_customizacao != null && linha.Cores_customizacao != '-' && linha.Cores_customizacao != '0') item.Cores_de_customizacao__c = linha.Cores_customizacao;
                            if(linha.Numero_de_impressoes_xc != null) item.Numero_de_impressoes__c = linha.Numero_de_impressoes_xc;
                            if(linha.Numero_de_repeticoes_xc != null) item.Numero_de_repeticoes__c = linha.Numero_de_repeticoes_xc;
                            if(linha.Tecnica_xc != null && linha.Tecnica_xc != '-') item.Tecnica__c = linha.Tecnica_xc;
                            //if(linha.Transportadora_xc != null && linha.Transportadora_xc != '-') item.Transportadora__c = linha.Transportadora_xc;
                            if(linha.Stock_cativo_xc != null) item.Stock_cativo__c = linha.Referencia_SKU_xc == 'NSIMPEXTRA' ? true : linha.Stock_cativo_xc;
                            
                            String code = linha.Referencia_SKU_xc != '' && linha.Referencia_SKU_xc.contains('.') ?
                                linha.Referencia_SKU_xc.split('\\.')[0] : linha.Referencia_SKU_xc;
                            String color = linha.Referencia_SKU_xc != '' && linha.Referencia_SKU_xc.contains('.') ? 
                                (linha.Referencia_SKU_xc.split('\\.')[1].contains('-') ? 
                                 linha.Referencia_SKU_xc.split('\\.')[1].split('-')[0] : linha.Referencia_SKU_xc.split('\\.')[1])
                                : '';
                            String size = linha.Referencia_SKU_xc != '' && linha.Referencia_SKU_xc.contains('-') ? linha.Referencia_SKU_xc.split('-')[1] : '';
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
                            /*if(linha.Referencia_SKU_xc == 'NSIMPEXTRA'){
                                item.Auxiliar_expedicao__c = 1;
                            }*/
                        
                            newCodes.add(code);
                            newSizes.add(size);
                            tempList.add(temp);//lista para mapear os pbes
                        }
                    }
                }
                
                
                system.debug('listOli '+ listOli);
                
                
                checkRecursive.runRecalcExp = true;
                if(!listOli.isEmpty()) upsert listOli.values();
                checkRecursive.runRecalcExp = false;
                
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
                Opportunity auxOpp = [Select Id, Description, Autorizada__c, Erro_comunicacao__c, Versao_enviada__c,Espera_de_integracao__c from Opportunity Where Id = :opp.Id];
                boolean updateOpp = false;
                //auxOpp.Espera_de_integracao__c = false;
                
                //Keidy - Espera de integração com valor diferente do atual.
                auxOpp.Espera_de_integracao__c = !auxOpp.Espera_de_integracao__c;
                
                auxOpp.Erro_comunicacao__c = false;
                auxOpp.Versao_enviada__c = auxOpp.Versao_enviada__c != null ? auxOpp.Versao_enviada__c + 1 : 1;
                if(result.mensagemErro != null && result.mensagemErro != ''){
                    system.debug(LoggingLevel.INFO, 'Primeira validação');
                    auxOpp.Description = auxOpp.Description != null ? auxOpp.Description + '\n' + System.now().format() + ': ' + result.mensagemErro + ';' : System.now().format() + ': ' + result.mensagemErro;
                    auxOpp.Erro_comunicacao__c = true;
                    updateOpp = true;
                }
                if(result.Data_de_faturacao_xc == errorDate){ 
                    system.debug(LoggingLevel.INFO, 'Segunda validação');
                    auxOpp.Description = auxOpp.Description != null ? auxOpp.Description + '\n' + System.now().format() + ': Erro integração;' : System.now().format() + ': Erro integração;';
                    auxOpp.Erro_comunicacao__c = true;
                    updateOpp = true;
                }
                if(auxOpp.Id == result.idSalesForceDossier){
                    system.debug(LoggingLevel.INFO, 'Terceira validação');
                    updateOpp = true;
                    if(auxOpp.Autorizada__c == '' || auxOpp.Autorizada__c == null){
                        if(result.Referencia_PHC_xc != 0){
                            if(result.Stamp_xc != null) auxOpp.Stamp__c = result.Stamp_xc;
                            if(result.idSalesForceDossier != null) auxOpp.Id = result.idSalesForceDossier;
                            if(result.Numero_de_volumes_xc != null) auxOpp.Numero_de_volumes__c = result.Numero_de_volumes_xc;
                            if(result.N_de_expedicao_xc != null) auxOpp.N_de_expedicao__c = String.valueOf(result.N_de_expedicao_xc);
                            //auxOpp.Volumes__c = String.valueOf(result.Volumes_xc);
                            if(result.Data_de_faturacao_xc != null && result.Data_de_faturacao_xc > nullDate) auxOpp.Data_de_faturacao__c = result.Data_de_faturacao_xc.date();
                            if(result.Custo_de_transporte_Stricker_xc != null) auxOpp.Custo_de_transporte_Stricker__c = result.Custo_de_transporte_Stricker_xc;
                            if(result.Data_de_conclusao_de_producao_xc != null && result.Data_de_faturacao_xc > nullDate)
                                auxOpp.Data_de_conclusao_de_producao__c = result.Data_de_conclusao_de_producao_xc;
                            if(result.Nweb_xc != null) auxOpp.Nweb__c = String.valueOf(result.Nweb_xc);
                            if(result.Referencia_PHC_xc != null) auxOpp.Referencia_PHC__c = String.valueOf(result.Referencia_PHC_xc);
                            //auxOpp.Erro__c = result.erros;
                            if(result.CloseDate != null && result.CloseDate >= nullDate) auxOpp.CloseDate = result.CloseDate.date();
                            if(result.logi4 != null) auxOpp.Nao_calcula_portes_automaticos__c = result.logi4;
                            //if(result.nvmaqteaceite != null && result.nvmaqteaceite != '') auxOpp.Nao_calcula_portes_automaticos__c = result.nvmaqteaceite;
                            //Keidy - Quando o tabela1 == 'ANULADO' o stageName da opp passa para 'Fechado anulado'.
                            if(result.tabela1 != null && result.tabela1 == 'ANULADO'){
                                auxOpp.StageName = 'Fechado anulado';
                            }else if(result.tabela1.toLowerCase() == 'fechado faturado'){
                                auxOpp.StageName = 'Fechado faturado';
                            }
                        }else{
                            auxOpp.Erro_comunicacao__c = true;
                        }
                        if(!auxOpp.Erro_comunicacao__c) auxOpp.Espera_de_integracao__c = doBreak;
                        else auxOpp.Espera_de_integracao__c = false;
                    }
                }
                if(updateOpp) update auxOpp;
            }
            else{
                Opportunity auxOpp = [Select Id, Description, Autorizada__c, Erro_comunicacao__c, Espera_de_integracao__c, Versao_enviada__c from Opportunity Where Id = :opp.Id];
                
                auxOpp.Erro_comunicacao__c = false;
                auxOpp.Versao_enviada__c = auxOpp.Versao_enviada__c != null ? auxOpp.Versao_enviada__c + 1 : 1;
                if(result.mensagemErro != null && result.mensagemErro != ''){
                    system.debug(LoggingLevel.INFO, 'Primeira validação');
                    auxOpp.Description = auxOpp.Description != null ? auxOpp.Description + '\n' + System.now().format() + ': ' + result.mensagemErro + ';' : System.now().format() + ': ' + result.mensagemErro;
                    auxOpp.Erro_comunicacao__c = true;
                }
                if(result.Data_de_faturacao_xc == errorDate){ 
                    system.debug(LoggingLevel.INFO, 'Segunda validação');
                    auxOpp.Description = auxOpp.Description != null ? auxOpp.Description + '\n' + System.now().format() + ': Erro integração;' : System.now().format() + ': Erro integração;';
                    auxOpp.Erro_comunicacao__c = true;
                }
                //auxOpp.Espera_de_integracao__c = false;
                
                //Keidy - Espera de integração com valor diferente do atual.
                auxOpp.Espera_de_integracao__c = !auxOpp.Espera_de_integracao__c;
                
                try{
                    update auxOpp;
                }catch(Exception Ex){
                    UtilClaims.sendEmailFailure('Falha de update dossier autorizado', '' + auxOpp + '\r\n' + ex.getMessage());
                   if(!ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) throw new DMLException('Bateu no update');
                }
            }
        }
        system.debug(doBreak);
        return doBreak;
    }
    
    public static boolean trataRespostaDossierFIFO(clientStricker.stampUpSet result, Opportunity opp){
        system.debug(result);
        //existem erros
        Boolean falhou = result.erros != 0;
        if(falhou){
            UtilClaims.sendEmailFailure('Falha envio dossier FIFO', 'Resultado: ' + result + '\r\nOpprtunity: ' + opp);
        }
        //retorna true para voltar a agendar
        return falhou;
    }
    @future(callout=true)
    public static void criaPrecosCliente(Id clientId){
        if(clientId != null){
            Account acc = buildAccountPPC(clientId);
            User user = buildUserPPC(acc.OwnerId);
            
            criaPrecosClienteWork(acc, user);
        }
    }
    
    public static Account buildAccountPPC(String accId){
        return [Select Id,OwnerId,Numero_de_cliente__c,
                (Select Id, Produto__r.ProductCode,Produto__r.Tamanho__c,Valor__c,Data_de_inicio__c,Data_de_fim__c From Precos_por_cliente__r)
                From Account Where Id = :accId];
    }
    
    public static User buildUserPPC(String accOwner){
        return [Select Id, Codigo_de_Utilizador__c From User Where Id = :accOwner];
    }
    
    public static void criaPrecosClienteWork(Account acc, User user){
        try{
            servico.timeout_x = 120000;
            clientStricker.PrecoClienteRetorno retorno = servico.criaPrecosCliente(buildTPC(acc, user));
            system.debug(retorno);
        }catch(Exception ex){
            system.debug('ERROR: ' + ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }
    
    @future(callout=true)
    public static void updatePrecosCliente(Id clientId){/*, Set<Id> linhas RETIRADO 2018-02-01 para o integrador poder apagar as linhas todas e voltar a criar numa actualização*/
        if(clientId != null){
            Account acc = [Select Id,OwnerId,Numero_de_cliente__c,
                           (Select Id, Produto__r.ProductCode,Produto__r.Tamanho__c,Valor__c,Data_de_inicio__c,Data_de_fim__c From Precos_por_cliente__r)
                           From Account Where Id = :clientId];
            User user = [Select Id, Codigo_de_Utilizador__c From User Where Id = :acc.OwnerId];
            
            updatePrecosClienteWork(acc, user);
        }
    }
    
    public static void updatePrecosClienteWork(Account acc, User user){
        try{
            servico.timeout_x = 120000;
            // chamada ao método 
            clientStricker.PrecoClienteRetorno retorno = servico.actualizaPrecosCliente(buildTPC(acc, user));
            system.debug(retorno);
            
        }catch(Exception ex){
            system.debug('ERROR: ' + ex.getMessage());
        }
    }
    private static clientStricker.TabelaPrecosCliente buildTPC(Account acc, User user){
        
        //cria estrutura de entrada no pedido
        clientStricker.TabelaPrecosCliente tpc = new clientStricker.TabelaPrecosCliente();
        tpc.Numero_de_cliente = Decimal.valueOf(acc.Numero_de_cliente__c);
        tpc.UtilizadorLogado = [Select id, Alias From User Where Id = :UserInfo.getUserId()].Alias;
        tpc.vendedor = user.Codigo_de_utilizador__c != null ? Integer.valueOf(user.Codigo_de_utilizador__c) : 139;
        tpc.listaLinhasPrecos = new clientStricker.ArrayOfLinhaPrecoCliente();
        tpc.listaLinhasPrecos.LinhaPrecoCliente = new List<clientStricker.LinhaPrecoCliente>();
        
        //cria linhas
        for(Preco_por_cliente__c pc : acc.Precos_por_cliente__r){
            clientStricker.LinhaPrecoCliente lpc = new clientStricker.LinhaPrecoCliente();
            lpc.idSalesForce = pc.Id;
            lpc.Referencia_SF = pc.Produto__r.ProductCode != null ? pc.Produto__r.ProductCode : '';
            lpc.tamanho = pc.Produto__r.Tamanho__c != null ? pc.Produto__r.Tamanho__c : '';
            lpc.Preco_unitario = pc.Valor__c != null ?  pc.Valor__c : 0;
            lpc.dataInicio = pc.Data_de_inicio__c != null ? pc.Data_de_inicio__c : Date.newInstance(1900, 1, 1);
            lpc.dataFim = pc.Data_de_fim__c != null ? pc.Data_de_fim__c : Date.newInstance(1900, 1, 1);
            
            tpc.listaLinhasPrecos.LinhaPrecoCliente.add(lpc);
        }
        system.debug(tpc);
        return tpc;
    }
    
    public static Opportunity getOpp(Id oppId){
        
        String oliQuery = 'Select ';
        boolean isFirst = true;
        
        for(String s : Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().keySet()){
            if(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get(s).getDescribe().isAccessible()){
                //system.debug(s);
                if(isFirst){
                    isFirst= false;
                }else{
                    oliQuery += ',';
                }
                oliQuery += s;
            }
        }
        oliQuery += ',(Select ';
        isFirst = true;
        for(String s : Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().keySet()){
            //system.debug('String s: ' + s);
            //system.debug(Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().get(s).getDescribe().isAccessible());
            if(Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().get(s).getDescribe().isAccessible()){
                if(isFirst){
                    isFirst= false;
                }else{
                    oliQuery += ',';
                }
                oliQuery += s;
            }
        }
        
        oliQuery += (isFirst ? '' : ',')
            +'Product2.Name,'
            +'Product2.Referencia_relacionada__c,'
            +'Product2.Nome_do_produto_DE__c,'
            +'Product2.Nome_do_produto_en_US__c,'
            +'Product2.Nome_do_produto_ES__c,'
            +'Product2.Nome_do_produto_FR__c,'
            +'Product2.Nome_do_produto_it__c,'
            +'Product2.Nome_do_produto_NL__c,'
            +'Product2.Nome_do_produto_PL__c,'
            +'Product2.Nome_do_produto_pt_BR__c,'
            +'Product2.Nome_do_produto_RU__c,'
            +'Product2.Nome_do_produto_DE_PHC__c,'
            +'Product2.Nome_do_produto_en_US_PHC__c,'
            +'Product2.Nome_do_produto_ES_PHC__c,'
            +'Product2.Nome_do_produto_FR_PHC__c,'
            +'Product2.Nome_do_produto_it_PHC__c,'
            +'Product2.Nome_do_produto_NL_PHC__c,'
            +'Product2.Nome_do_produto_PL_PHC__c,'
            +'Product2.Nome_do_produto_pt_BR_PHC__c,'
            +'Product2.Nome_do_produto_RU_PHC__c,'
            +'Product2.RecordType.DeveloperName,'
            +'Product2.Tabela_de_customizacoes__c,'
            +'Product2.Peso_caixa__c,'
            +'Product2.Caixa_interior_unidades__c,'
            +'Expedicao__r.Morada_aux__c,'
            +'Expedicao__r.Ao_Cuidado_De__c,'
            +'Expedicao__r.Morada_de_Entrega__r.Ao_Cuidado_De__c,'
            +'Expedicao__r.Transportadora__c,'
            +'Expedicao__r.Morada_de_Entrega__r.MSEQ__c,'
            +'Expedicao__r.Morada_de_Entrega__r.Codigo_postal__c,'
            +'Expedicao__r.Morada_de_Entrega__r.Localidade__c,'
            +'Expedicao__r.Morada_de_entrega__r.Morada_de_entrega__c,'
            +'Expedicao__r.Morada_de_Entrega__r.Pais__c,'
            +'Expedicao__r.Recolha_do_cliente__c,'
            +'Expedicao__r.Morada_de_Entrega__r.Nome_da_empresa__c'
            +' From OpportunityLineItems),'
            +'Account.Numero_de_cliente__c,Account.Tipologia_de_facturacao__c,Account.Name,Pedido_por__r.Name From Opportunity where Id  = \'' +oppId+ '\'';
        
        system.debug(oliQuery);
        return Database.query(oliQuery);
    }
    
    public static String queryBuilder(String objectName){
        
        String query = '';
        
        Boolean isFirst = true;
        
        for(Schema.FieldSetMember field : objectQueryFields(objectName)){
            if(isFirst){
                query += field.getFieldPath();
                isFirst = false;
            }else{
                query += ' ,'+field.getFieldPath();
            }
        }
        
        return query;
    }
    
    public static List<Schema.FieldSetMember> objectQueryFields(String objectName){
        
        List<Schema.FieldSetMember> queryFields = new List<Schema.FieldSetMember>();
        
        if(objectName == 'Account'){
            queryFields = SObjectType.Account.FieldSets.Integration_Fields.getFields();
        }else if((objectName == 'Contact')){
            queryFields = SObjectType.Contact.FieldSets.Integration_Fields.getFields();
        }else if((objectName == 'Morada_de_Entrega__c')){
            queryFields = SObjectType.Morada_de_Entrega__c.FieldSets.Integration_Fields.getFields();
        }
        
        return queryFields;
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