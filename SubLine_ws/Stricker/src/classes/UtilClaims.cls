public class UtilClaims {
    public static final List<String> compareLinFields = new List<String>{'ref','desc','qtt'};
    //lista de campos usada na pesquisa das moradas do componente cmp_ChooseLines
    public static final List<String> compareMoradasFields = new List<String>{'rua'};
    public static boolean compareValues(String value, String filter){
        if(value != null){
            value = value.toLowerCase();
            filter = filter.toLowerCase();
            if(value.contains(filter)){
                return true;
            } 
        }else if(filter == ''){
            return true;
        }
        return false;
    }
    
    public static void sendEmailFailure(String subject, String body){
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
        
        mail.setSubject(subject);
        
        mail.setPlainTextBody(body);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        delete c;
    }
    
    /* Estrutura que representa uma linha possivel de ser reclamada
     * @params:
     * @selected: foi selecionado?
     * @ftstamp: Stamp do ficheiro PHC
     * @bostamp: Stamp do dossier PHC
     * */
    public class LinhasDoc implements Comparable{
        public boolean selected {get;set;}
        public String ftstamp {get;set;}
        public String bostamp {get;set;}
        public String moeda {get;set;}
        public String moedaSymbol {get;set;}
        public Decimal total {get;set;}
        public String uniqueId {get;set;}
        public String cliente {get;set;}
        public String auxData {get;set;}
        public OrderItem details {get;set;}
        
        public LinhasDoc(){}
        
        public LinhasDoc(String ftstamp, String bostamp){
            selected = true;
            this.ftstamp = ftstamp.trim();
            this.bostamp = bostamp.trim();
            
            details = new OrderItem();
            details.Quantidade_original__c = 250;
            details.Referencia_SKU__c = '81004.03';
        }
        
        
        public LinhasDoc(String ftstamp, String bostamp,String uniqueId, wsdl_Claims.LinDocFinCliente line/*, String vend, String pbeId*/){
            selected = false;
            details = new OrderItem();
            this.uniqueId = uniqueId;
            this.ftstamp = ftstamp != null ? ftstamp.trim() : '';
            this.bostamp = line.bostamp != null ? line.bostamp.trim() : '';
            this.cliente = String.valueOf(line.cliente);
            //Integer fatura;
            //case.Account = new Account(line.cliente);
            //Integer ano;
            //String tipo;
            //String descTipo;
            details.Pais__c = line.pais;
            details.Data_de_emissao_do_documento_financeiro__c = line.data != null ? line.data.date() : null;
            moeda = line.moeda == 'PTE ou EURO' ? 'EUR' : line.moeda;
            moedaSymbol = line.moeda == 'PTE ou EURO' ? Utils.currencySymbol('EUR') : Utils.currencySymbol(line.moeda);
            details.Referencia_PHC__C = line.referencia;
            details.Cor__c = line.cor != null && line.cor.length() > 3 ? line.cor.left(3) : line.cor;
            details.Tamanho__c = line.tam;
            details.Referencia_SKU__c = line.refSF;
            details.Description = line.descricao;
            details.Quantidade_original__c = line.qtt;
            details.UnitPrice = line.preco != null ? line.preco.stripTrailingZeros() : null;
            details.Taxa_de_IVA__c = line.iva;
            details.Tabela_de_IVA__c = String.valueOf(line.tabiva);
            details.Desconto__c = line.discount;
            //Decimal discount2;
            total = line.total != null ? line.total.stripTrailingZeros() : null;
            details.Lote__c = line.lote != null ? line.lote.trim() : '';
            details.Rua_original__c = line.rua_morada;
            details.Zona_de_envio__c = line.zona_morada;
            details.Contacto_original__c = line.cont_morada;
            details.Codigo_postal_original__c = line.codpost_morada;
            details.Localidade_original__c = line.local_morada;
            details.Telefone_original__c = line.phone_morada;
            details.Bostamp__c = line.bostamp != null ? line.bostamp.trim() : '';
            details.Fistamp__c = line.fistamp != null ? line.fistamp.trim() : '';
            details.Oftstamp__c = line.oftstamp != null ? line.oftstamp.trim() : '';
            details.Bistamp__c = line.bistamp != null ? line.bistamp.trim() : '';
            details.Preco_original__c = line.preco_origin;
            details.Custo_ponderado__c = line.cust_pond;
            details.Volume__c = line.vol;
            details.Peso__c = line.peso;
            details.Data_de_expedicao_da_mercadoria__c = line.data_env;
            // pbruto;
            details.Vendedor__c = line.vend;
            details.Transportadora__c = line.transportadoraFT;
            details.Custo_de_portes__c = line.custoPortesFT;
            details.Tracking_number_original__c = line.tracking;
            details.Numero_de_caixas__c = line.n_caixas;
            details.NDos__c = line.ndosBI;
            details.Tipo_dossier_abreviado__c = utils.getDossTypeShortName(line.ndosBI);
        }
        
        public Integer compareTo(Object compareTo) {
            LinhasDoc compareToCust = (LinhasDoc)compareTo;
            Integer returnValue = 0;
            
            if(this.details.fistamp__c > compareToCust.details.fistamp__c){
                returnValue = 1;       
            }else if(this.details.fistamp__c < compareToCust.details.fistamp__c){
                returnValue = -1;   
            }
            return returnValue;
        }
        
        public LinhasDoc cloneThis(){
            LinhasDoc theClone = (LinhasDoc)JSON.deserialize(JSON.serialize(this), LinhasDoc.class);
            theClone.uniqueId = theClone.details.Fistamp__c + system.now();
            theClone.details.Quantity = null;
            theClone.details.Tipologia__c = null;
            theClone.details.Sub_tipologia__c = null;
            theClone.details.Comentario_do_cliente__c = null;
            theClone.details.Morada_correta__c = null;
            theClone.details.Rua_correta__c = null;
            theClone.details.MSEQ_Morada_Correta__c = null;
            return theClone;
        }
        
        public String get(String field){
            if(field == 'ref'){
                return this.details.Referencia_SKU__c != null ? this.details.Referencia_SKU__c : '';
            }else if(field == 'desc'){
                return this.details.Description != null ? this.details.Description : '';
            }else if(field == 'qtt'){
                return this.details.Quantidade_original__c != null ? String.valueOf(this.details.Quantidade_original__c) : '';
            }else{
                return null;
            }
        }
    }
    
    
    //lista de campos que são comparados pela pesquisa (get(field);)
    public static final List<String> compareDocFields = new List<String>{'data_emissao','data_vencime','cred_emitido','custo_portes','refInterna','name'};
        
    
    public static boolean validateToken(String token, Token_site__c tok){
        boolean isValid = false;
        if(tok.Token__c == token){
            system.debug('Token valido');
            if(tok.Validado__c){
                isValid = true;
            }else{
                if(tok.Data_de_validade__c > System.now()){
                    //validação de ip se necessária
                    isValid = true;
                }
            }
        }
        
        return isValid;
    }
    
    public static Case verificarCaso(Case caso, List<Pedido_de_parecer__c> pedidos){
        boolean temRecolhaAberto = false;
        boolean temFotosAberto = false;
        boolean temParecerPendente = false;
        
        for(Pedido_de_parecer__c parecer : pedidos){
            if(parecer.Pedido_de_recolha_aberto__c){
                temRecolhaAberto = true;
            }
            if(parecer.Pedido_de_fotos_aberto__c){
                temFotosAberto = true;
            }
            if(parecer.Resposta_final__c == ''){
                temParecerPendente = true;
            }
        }
        if(temRecolhaAberto){
            caso.Sub_estado__c = 'Aguardar confirmação de pedido de recolha';
        }else if(temFotosAberto){
            caso.Sub_estado__c = 'Aguardar fotos do cliente';
        }else if(temParecerPendente){
            caso.Sub_estado__c = 'Aguardar resposta de parecer';
        }
        return caso;
    }
    
    @future
    public static void permaValidateToken(String tokenId){
        Token_Site__c tok = new Token_site__c(Id = tokenId, Validado__c = true);
        
        update tok;
    }
    /* Estrutura que representa uma linha possivel de ser reclamada
     * @selected : true se a linha tiver sido escolhida pelo utilizador;
     * @name : nome do documento
     * @ftstamp : Stamp do documento
     * @bostamp : Stamp do dossier associado ao documento;
     * @fats : Estrutura JSON com a lista de faturas associadas a este dossier;
     * */
    public class NewClaimLine{
        public boolean selected {get;set;}
        public String name {get;set;}
        public String ftstamp {get;set;}
        public String bostamp {get;set;}
        public Decimal custo_total {get;set;}
        public String vendedor {get;set;}
       // public boolean isClaimed {get;set;}
        public String refInterna {get;set;}
        public Integer fno {get;set;}
        //DOC
        public Decimal cred_emitido_moed {get;set;}
        public Decimal cred_regularizado_euro {get;set;}
        public Decimal cred_emitido_euro {get;set;}
        public Decimal cred_regularizado_moed {get;set;}
        public Decimal deb_regularizado_moed {get;set;}
        public Decimal deb_regularizado_euro {get;set;}
        public Decimal deb_emitido_euro {get;set;}
        public Decimal deb_emitido_moeda {get;set;}
        public String moeda {get;set;}
        public String moedaSymbol {get;set;}
        public String tipo_documen {get;set;}
        public DateTime data_emissao {get;set;}
        public Integer ano {get;set;}
        public DateTime data_validad {get;set;}
        public DateTime data_pagamento {get;set;}
        public DateTime data_vencime {get;set;}
        public Decimal custo_portes {get;set;}
        public String codigo_pais {get;set;}
        //DOSS
        public DateTime data_env {get;set;}
        
        //lista de faturas de um dossier
        public String fats {get;set;}
        
        public List<Morada> moradas {get;set;}
        
        public NewClaimLine(String name, String ftstamp, String bostamp, List<Fatura> fats){
            selected = false;
            this.name = name;
            this.ftstamp = ftstamp;
            this.bostamp = bostamp;
            this.fats = JSON.serialize(fats);
        }
        
        public NewClaimLine(wsdl_Claims.DocFinCliente doc/*, boolean isClaimed*/){
            Datetime nullDate = Datetime.newInstance(1900, 1, 1);
            selected = false;
            this.name = doc.tipo_documen + ' ' + doc.fno + (doc.data_emissao != null ? ' - ' + doc.data_emissao.year() : '');
            this.ftstamp = doc.ftstamp;
            this.bostamp = '';
            this.cred_emitido_moed = doc.cred_emitido_moed;
            this.cred_regularizado_euro = doc.cred_regularizado_euro;
            this.cred_emitido_euro = doc.cred_emitido_euro;
            this.cred_regularizado_moed = doc.cred_regularizado_moed;
            this.deb_regularizado_moed = doc.deb_regularizado_moed;
            this.deb_regularizado_euro = doc.deb_regularizado_euro;
            this.deb_emitido_euro = doc.deb_emitido_euro;
            this.deb_emitido_moeda = doc.deb_emitido_moeda;
            this.moeda = doc.moeda == 'PTE ou EURO' ? 'EUR' : doc.moeda;
            this.moedaSymbol = doc.moeda == 'PTE ou EURO' ?  Utils.currencySymbol('EUR') : Utils.currencySymbol(doc.moeda);
            this.tipo_documen = doc.tipo_documen;
            this.data_emissao = doc.data_emissao > nullDate ? doc.data_emissao : null;
            this.ano = this.data_emissao != null ? this.data_emissao.year() : null;
            this.data_validad = doc.data_validad > nullDate ? doc.data_validad : null;
            this.data_pagamento = doc.data_pagamento > nullDate ? doc.data_pagamento : null;
            this.data_vencime = doc.data_vencime > nullDate ? doc.data_vencime : null;
            this.custo_portes = doc.custo_portes;
            this.custo_total = doc.custo_total;
            this.codigo_pais = doc.codigo_pais;
            this.fats = null;
            this.fno = doc.fno;
            //this.isClaimed = isClaimed;
        }
        
        public NewClaimLine(wsdl_Claims.DossierByCliente doss/*, boolean isClaimed*/){
            this.selected = false;
            this.ftstamp = doss.ftstamp;
            this.bostamp = doss.bostamp != null ? doss.bostamp.trim() : '';
            this.name = doss.numDos + ' - ' + Utils.getDossTypeName(doss.ndos);
            this.data_emissao = doss.data_fat;
            this.data_env = doss.data_env;
            this.custo_total = doss.total;
            this.vendedor = doss.vendedor;
            //this.isClaimed = isClaimed;
            this.refInterna = doss.refInterna;
            this.moeda = doss.moeda == 'PTE ou EURO' ? 'EUR' : doss.moeda;
            this.moedaSymbol = doss.moeda == 'PTE ou EURO' ? Utils.currencySymbol('EUR') : Utils.currencySymbol(doss.moeda);
            if(doss.moradasDossier != null){
                moradas = new List<Morada>();
                for(wsdl_Claims.DossiersMoradas mor : doss.moradasDossier.DossiersMoradas){
                    Morada novaMorada = new Morada(mor.rua_mor, mor.codigo_postal_mor, mor.localidade_mor, mor.pais_mor, mor.transp);
                    
                    moradas.add(novaMorada);
                }
            }
            
            //construir faturas;
            if(doss.faturasDossier != null){
                List<Fatura> faturas = new List<Fatura>();
                for(wsdl_Claims.DossiersDocsFin fat : doss.faturasDossier.DossiersDocsFin){
                    Fatura newFat = new Fatura(String.valueOf(fat.ndoc), fat.ftstamp, bostamp, fat.data_emissao);
                    
                    faturas.add(newFat);
                }
                //dummy data
                //faturas.add(new Fatura(String.valueOf(1), 'JOR18011264552,562225505', 'ISA18011250578,380000001', system.now()));
                //faturas.add(new Fatura(String.valueOf(2), 'JOR18011264552,562225505', 'ISA18011250861,677000002', system.now()));
                
                fats = JSON.serialize(faturas);
            }
        }
        
        public NewClaimLine(Documentos_financeiros__c doc){
            Datetime nullDate = Datetime.newInstance(1900, 1, 1);
            selected = false;
            this.name = doc.Name;
            this.ftstamp = doc.Ftstamp__c;
            this.bostamp = '';
            this.cred_emitido_moed = doc.Valor_credito_emitido_moeda__c;
            this.cred_regularizado_euro = doc.Valor_credito_emitido_euros_regularizado__c;
            this.cred_emitido_euro = doc.Valor_credito_emitido_euros__c;
            this.cred_regularizado_moed = doc.Valor_credito_emitido_moeda_regularizado__c;
            this.deb_regularizado_moed = doc.Valor_debito_emitido_moeda_regularizado__c;
            this.deb_regularizado_euro = doc.Valor_debito_emitido_euros_regularizado__c;
            this.deb_emitido_euro = doc.Valor_debito_emitido_euros__c;
            this.deb_emitido_moeda = doc.Valor_debito_emitido_moeda__c;
            this.moeda = doc.CurrencyIsoCode;
            this.moedaSymbol = moeda == 'PTE ou EURO' ?  Utils.currencySymbol('EUR') : Utils.currencySymbol(moeda);
            this.tipo_documen = String.valueOf(doc.Tipo_de_documento__c);
            this.data_emissao = doc.Data__c;
            this.ano = this.data_emissao != null ? this.data_emissao.year() : null;
            this.data_validad = doc.Data_de_validade__c;
            this.data_pagamento = doc.Data_de_pagamento__c > nullDate ? doc.Data_de_pagamento__c : null;
            //this.data_vencime = doc.data_vencime > nullDate ? doc.data_vencime : null;
            //this.custo_portes = doc.custo_portes;
            this.custo_total = doc.Valor_debito__c;
            //this.codigo_pais = doc.;
            //this.fats = null;
            //this.fno = doc.fno;
        }
        
        //metodo usado para o filtro de linha base da reclamação
        public String get(String field){
            if(field == 'data_emissao'){
                return this.data_emissao != null ? this.data_emissao.format('dd-MM-yyyy') : '';
            }else if(field == 'data_vencime'){
                return this.data_vencime != null ? this.data_vencime.format('dd-MM-yyyy') : '';
            }else if(field == 'cred_emitido'){
                return this.moeda == 'EUR' ? String.valueOf(this.cred_emitido_euro) : String.valueOf(this.cred_emitido_moed);
            }else if(field == 'custo_portes'){
                return String.valueOf(this.custo_portes);
            }else if(field == 'refInterna'){
                return String.valueOf(this.refInterna);
            }else if(field == 'name'){
                return String.valueOf(this.name);
            }else{
                return null;
            }
        }
    }
    
    /* Estrutura que representa uma linha de um documento associado ao dossier
     * @selected : true se a linha tiver sido escolhida pelo utilizador;
     * @name : nome do documento
     * @ftstamp : Stamp do documento
     * @bostamp : Stamp do dossier associado ao documento;
     * */
    public class Fatura{
        public boolean selected {get;set;}
        public String name {get;set;}
        public String ftstamp {get;set;}
        public String bostamp {get;set;}
        public Datetime data_emissao {get;set;}
        
        public Fatura(String name, String ftstamp, String bostamp, Datetime data_emissao){
            selected = false;
            this.name = name;
            this.ftstamp = ftstamp;
            this.bostamp = bostamp;
            this.data_emissao = data_emissao;
        }
    }
    
    public class Morada{
        public String rua {get;set;}
        public String codPost {get;set;}
        public String local {get;set;}
        public String pais {get;set;}
        public String transp {get;set;}
        
        public Morada(String rua,String codPost,String local,String pais,String transp){
            this.rua = rua;
            this.codPost = codPost;
            this.local = local;
            this.pais = pais;
            this.transp = transp;
        }
    }
}