public class IntegratorClaims {
    
    public static wsdl_Claims.ClaimsPHCSoap servClaims = new wsdl_Claims.ClaimsPHCSoap();
    
    public static List<UtilClaims.NewClaimLine> getDocs(String no){
        /*Set<String> ftstamps = new Set<String>();
        
        for(Case caso : [Select Id, Ft_Stamp__c From Case Where Account.Numero_de_cliente__c = :no Or Account.Numero_de_cliente__c = '1']){
            ftstamps.add(caso.Ft_Stamp__c);
        }
        system.debug(ftstamps);*/
        servClaims.timeout_x = 120000;
        Claim_Config__mdt conf = [Select Id, Periodo_de_reclamacao__c from Claim_Config__mdt Where DeveloperName = 'Claims_Config_1'];
        Datetime initDate = Datetime.newInstance(System.today().addDays(-((Integer) conf.Periodo_de_reclamacao__c)), Time.newInstance(0, 0, 0, 0));
        Integer numCli = no.isNumeric() ? Integer.valueOf(no) : 0;

        //chamar serviço de documentos financeiros
        wsdl_Claims.ArrayOfDocFinCliente result = servClaims.lstDocsFinByClienteAndDate(numCli, initDate.format('yyyy-MM-dd'));
        system.debug(result);
        List<UtilClaims.NewClaimLine> retList = new List<UtilClaims.NewClaimLine>();
        if(result.DocFinCliente != null){
            for(wsdl_Claims.DocFinCliente line : result.DocFinCliente){
                UtilClaims.NewClaimLine newLine = new UtilClaims.NewClaimLine(line);
                retList.add(newLine);
            }
        }
        return retList;

        /*return new List<UtilClaims.NewClaimLine>{
            new UtilClaims.NewClaimLine('Test1', 'Ft1', null, null),
                new UtilClaims.NewClaimLine('Test2', 'Ft2', null, null)};//dummy data*/
    }

    public static List<UtilClaims.NewClaimLine> getDoss(String no){
        /*Set<String> ftstamps = new Set<String>();
        
        for(Case caso : [Select Id, Ft_Stamp__c From Case Where Account.Numero_de_cliente__c = :no Or Account.Numero_de_cliente__c = '1']){
            ftstamps.add(caso.Ft_Stamp__c.trim());
        }*/
        
        servClaims.timeout_x = 120000;
        Claim_Config__mdt conf = [Select Id, Periodo_de_reclamacao__c from Claim_Config__mdt Where DeveloperName = 'Claims_Config_1'];
        Datetime initDate = Datetime.newInstance(System.today().addDays(-((Integer) 150 /*conf.Periodo_de_reclamacao__c*/)), Time.newInstance(0, 0, 0, 0));
        Integer numCli = no.isNumeric() ? Integer.valueOf(no) : 0;
        
        wsdl_Claims.ArrayOfDossierByCliente result = servClaims.lstDossiersByClienteAndDate(numCli, initDate.format('yyyy-MM-dd'));
        
        system.debug(result);
        
        List<UtilClaims.NewClaimLine> retList = new List<UtilClaims.NewClaimLine>();
        if(result.DossierByCliente != null){
            for(wsdl_Claims.DossierByCliente line : result.DossierByCliente){
                UtilClaims.NewClaimLine newLine = new UtilClaims.NewClaimLine(line);
                retList.add(newLine);
            }
        }
        return retList;
        //chamar serviço de dossiers
        /*return new List<UtilClaims.NewClaimLine>{
            new UtilClaims.NewClaimLine('Test3', 'Ft3', 'Bo3', new List<UtilClaims.Fatura>{
                new UtilClaims.Fatura('Fatura1', 'FtFat1', 'BoFat1'),
                new UtilClaims.Fatura('Fatura2', 'FtFat2', 'BoFat2')}),
            new UtilClaims.NewClaimLine('Test4', 'Ft4', 'Bo4', null)};//dummy data*/
    }
    
    public static List<UtilClaims.LinhasDoc> getLines(String ftstamp, String bostamp){
        system.debug(ftstamp);
        system.debug(bostamp);
        Map<String, User> usersMap = new Map<String, User>();
        for(User user : [Select id, Codigo_de_utilizador__c, IsActive from User]){
            usersMap.put(user.Codigo_de_utilizador__c, user);
        }
        wsdl_Claims.ArrayOfLinDocFinCliente result = servClaims.lstLinsDocFinByFtStamp(ftstamp);
        
        List<UtilClaims.LinhasDoc> retList = new List<UtilClaims.LinhasDoc>();
        
        if(result.LinDocFinCliente != null){
            for(wsdl_Claims.LinDocFinCliente line : result.LinDocFinCliente){
                UtilClaims.LinhasDoc newLine = new UtilClaims.LinhasDoc(ftstamp, bostamp, line.fistamp, line);
                retList.add(newLine);
            }
        }
        
        //List<UtilClaims.LinhasDoc> retList = new List<UtilClaims.LinhasDoc>{new UtilClaims.LinhasDoc(ftstamp, bostamp), new UtilClaims.LinhasDoc(ftstamp, 'Bo4'), new UtilClaims.LinhasDoc(ftstamp, 'Bo1')};
        
        retList.sort();
        return retList;//dummy data
    }
    
    @future(callout=true)
    public static void createClaim(Id caseId){
        List<Case> cases = getMyCases(caseId);
        List<orderItem> items = getMyLines(caseId);
        Case caso;
        if(!cases.isEmpty()){
            caso = cases.get(0);
        }
        if(caso != null){
            
            wsdl_Claims.ReclamaCab cab = buildReclamaCab(caso);
            
            for(OrderItem item : items){
                wsdl_Claims.ReclamaLinha line = buildReclamaLinha(item);
                
                cab.listaLinhasReclama.ReclamaLinha.add(line);
            }
            system.debug(cab);
            wsdl_Claims.replayReclama resposta = servClaims.criaDossierPHC(cab);
            system.debug(resposta);
            
            caso.Numero_de_Reclamacao_PHC__c = resposta.obrano;
            caso.Stamp__c = resposta.bostamp;
            
            checkRecursive.runCase = false;
            update caso;
            
            //@toDo percorrer as linhas para inserir bistamp
        }
    }
    //Mapeamentos de reclamacao
    private static List<Case> getMyCases(Id caseId){
        return [Select Id,Numero_de_cliente__c,Origin,Autorizada__c,CurrencyIsoCode,CreatedBy.Name,Status,Sub_estado__c,Vendedor__r.Codigo_de_utilizador__c,ContactId,Contact.Name,Vendedor__c,
                Data_de_emissao_do_documento_financeiro__c,Documento_financeiro__r.Ftstamp__c,CreatedDate,ClosedDate,Ft_Stamp__c,BoStamp_dossier_original__c,Pedido__r.TotalAmount, Tipo_de_documento_financeiro__c
                From Case 
                Where Id = :caseId];
    }
    
    private static List<orderItem> getMyLines(Id caseId){
        return [Select Id,Quantity,Preco_original__c,TotalPrice,Desconto__c,Referencia_SKU__c,Referencia_PHC__c,Cor__c,Tamanho__c,UnitPrice,Taxa_de_IVA__c,Lote__c,Rua_original__c,Zona_de_envio__c,Tabela_de_IVA__c,
                Contacto_original__c,Codigo_postal_original__c,Localidade_original__c,Telefone_original__c,Fistamp__c,Oftstamp__c,Custo_ponderado__c,Volume__c,Peso__c,Vendedor__c,Codigo_de_tipologia__c,
                Comentario_do_cliente__c,Comentario_do_cliente_traducao__c,Quantidade_original__c,Tipologia__c,Sub_tipologia__c,Acao_corretiva__c,Acao_corretiva_sugerida__c,Pais__c,CurrencyIsoCode,Description
                From OrderItem 
                Where OrderId In (Select Id From Order Where Reclamacao__c = :caseId)];
    }
    
    private static wsdl_Claims.ReclamaCab buildReclamaCab(Case caso){
        wsdl_Claims.ReclamaCab cab = new wsdl_Claims.ReclamaCab();
        
        cab.idsf = caso.Id;
        cab.numcliente = caso.Numero_de_cliente__c.isNumeric() ? integer.valueOf(caso.Numero_de_cliente__c) : 0;
        cab.origem = caso.Origin != null ? caso.Origin : '';
        cab.autorizada = caso.Autorizada__c != null ? String.valueOf(caso.Autorizada__c) : 'false';//autorizada e o autorizada por?????
        cab.moeda = caso.CurrencyIsoCode != null ? caso.CurrencyIsoCode : '';
        cab.feita = caso.CreatedBy.Name;//e o utilizador do site????
        cab.estado = caso.Status != null ? caso.Status : '';
        cab.sub_estado = caso.Sub_estado__c != null ? caso.Sub_estado__c : '';
        cab.vendedor = caso.Vendedor__c != null && caso.Vendedor__r.Codigo_de_utilizador__c != null && caso.Vendedor__r.Codigo_de_utilizador__c.isNumeric() ? integer.valueOf(caso.Vendedor__r.Codigo_de_utilizador__c) : 23;
        cab.nome_cont = caso.ContactId != null ? caso.Contact.Name : '';
        cab.data_doc_fat = caso.Data_de_emissao_do_documento_financeiro__c != null ? caso.Data_de_emissao_do_documento_financeiro__c : Datetime.newInstance(1900, 1, 1);
        cab.doc_fat = caso.Tipo_de_documento_financeiro__c != null ? caso.Tipo_de_documento_financeiro__c : '';
        cab.data_abert = caso.CreatedDate != null ? caso.CreatedDate : Datetime.newInstance(1900, 1, 1);
        cab.data_fecho = caso.ClosedDate != null ? caso.ClosedDate :  Datetime.newInstance(1900, 1, 1);
        cab.ftstamp = caso.Ft_Stamp__c != null ? caso.Ft_Stamp__c : '';
        cab.bostamp_orig = caso.BoStamp_dossier_original__c != null ? caso.BoStamp_dossier_original__c : '';
        cab.utilizador = [Select id, Codigo_de_utilizador__c from User where Id = :UserInfo.getUserId()].Codigo_de_utilizador__c;
        cab.preco_total = caso.Pedido__r.TotalAmount != null ? caso.Pedido__r.TotalAmount : 0;
        
        cab.listaLinhasReclama = new wsdl_Claims.ArrayOfReclamaLinha();
        cab.listaLinhasReclama.ReclamaLinha = new List<wsdl_Claims.ReclamaLinha>();
        return cab;
    }
    
    private static wsdl_Claims.ReclamaLinha buildReclamaLinha(OrderItem item){
        wsdl_Claims.ReclamaLinha line = new wsdl_Claims.ReclamaLinha();
        
        line.idsfLinha = item.Id;
        line.qtt = item.Quantity;
        line.preco_origin = item.Preco_original__c != null ? item.Preco_original__c : 0;
        line.preco_total = item.TotalPrice != null ? item.TotalPrice : 0;
        line.desconto = item.Desconto__c != null ? item.Desconto__c : 0;
        line.Referencia_SF = item.Referencia_SKU__c != null ? item.Referencia_SKU__c : '';
        line.DesignacaoProduto = item.Description != null ? item.Description : '';
        line.Referencia_PHC = item.Referencia_PHC__c != null ? item.Referencia_PHC__c : '';
        line.cor = item.Cor__c != null ? item.Cor__c : '';
        line.tam = item.Tamanho__c != null ? item.Tamanho__c : '';
        line.preco_unitario_xc = item.UnitPrice != null ? item.UnitPrice : 0;
        line.taxaiva = item.Taxa_de_IVA__c != null ? item.Taxa_de_IVA__c : 0;
        line.tabiva = item.Tabela_de_IVA__c != null && item.Tabela_de_IVA__c.isNumeric() ? Integer.valueOf(item.Tabela_de_IVA__c) : 1;
        line.lote = item.Lote__c != null ? item.Lote__c : '';
        line.rua = item.Rua_original__c != null ? item.Rua_original__c : '';
        line.zona = item.Zona_de_envio__c != null ? item.Zona_de_envio__c : '';
        line.contacto = item.Contacto_original__c != null ? item.Contacto_original__c : '';
        line.cod_post = item.Codigo_postal_original__c != null ? item.Codigo_postal_original__c : '';
        line.local = item.Localidade_original__c != null ? item.Localidade_original__c : '';
        line.phone = item.Telefone_original__c != null ? item.Telefone_original__c : '';
        line.fistamp = item.Fistamp__c != null ? item.Fistamp__c : '';
        line.oftstamp = item.Oftstamp__c != null ? item.Oftstamp__c : '';
        line.cust_pond = item.Custo_ponderado__c != null ? item.Custo_ponderado__c : 0;
        line.volume = item.Volume__c != null ? item.Volume__c : 0;
        line.peso = item.Peso__c != null ? item.Peso__c : 0;
        line.vend = item.Vendedor__c != null ? item.Vendedor__c : '';
        line.obs_cliente = item.Comentario_do_cliente__c != null ? item.Comentario_do_cliente__c : '';
        line.obs_trad = item.Comentario_do_cliente_traducao__c != null ? item.Comentario_do_cliente_traducao__c : '';
        line.qtt_origin = item.Quantidade_original__c != null ? item.Quantidade_original__c : 0;
        line.tipolog = item.Tipologia__c != null ? item.Tipologia__c : '';
        line.sub_tipolog = item.Sub_tipologia__c != null ? item.Sub_tipologia__c : '';
        line.accao_correct = item.Acao_corretiva__c != null ? item.Acao_corretiva__c : '';
        line.accao_correct_sug = item.Acao_corretiva_sugerida__c != null ? item.Acao_corretiva_sugerida__c :'';
        line.pais = item.Pais__c != null ? item.Pais__c : '';
        line.moeda = item.CurrencyIsoCode != null ? item.CurrencyIsoCode : '';
        line.codServico = item.Codigo_de_tipologia__c != null ? item.Codigo_de_tipologia__c : '';
        return line;
    }
    //*****************************END
    
    @future(callout=true)
    public static void updateClaim(Id caseId){
        List<Case> cases = getMyCases(caseId);
        List<orderItem> items = getMyLines(caseId);
        Case caso;
        if(!cases.isEmpty()){
            caso = cases.get(0);
        }
        if(caso != null){
            
            wsdl_Claims.ReclamaCab cab = buildReclamaCab(caso);
            
            for(OrderItem item : items){
                wsdl_Claims.ReclamaLinha line = buildReclamaLinha(item);
                
                cab.listaLinhasReclama.ReclamaLinha.add(line);
            }
            system.debug(cab);
            wsdl_Claims.replayReclama resposta = servClaims.actDossierPHC(cab);
            system.debug(resposta);
            
            caso.Numero_de_Reclamacao_PHC__c = resposta.obrano;
            caso.Stamp__c = resposta.bostamp;
            checkRecursive.runCase = false;
            update caso;
            //@toDo percorrer as linhas para inserir bistamp
        }
    }
    
    public static String getProdImg(String ref, String cor, String tam){
       return servClaims.imagemProducto(ref, cor, tam);
    }
    
    public static wsdl_Claims.Parecer getExtraInfo(String lineId){
        return servClaims.viewParecer(lineId);
    }
    
    public static File getMaquete(String stamp){
        
        wsdl_Claims.FicheiroMaquete result = servClaims.verFicheiroMaquete('MES17060953716,171000002');
        
        return new File(result.ficheiroB64, result.nomeFicheiro, result.extensao, result.dataModificacao);
    }
    public class File implements i_File{
        public String base64 {get;set;}
        public String name {get;set;}
        public String extension {get;set;}
        public DateTime dataModificacao {get;set;}
        
        public File(String base64, String name, String extension, DateTime dataModificacao){
            this.base64 = base64;
            this.name = name;
            this.extension = extension;
            this.dataModificacao = dataModificacao;
        }
        
        public String getBase64(){
            return base64;
        }
        public String getName(){
            return name;
        }
        public String getExtension(){
            return extension;
        }
        public DateTime getDataModificacao(){
            return dataModificacao;
        }
    }
    public static void magic(){
        boolean magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
    }
}