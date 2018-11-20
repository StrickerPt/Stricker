public class c_ViewerContaCorrente {
    public Account acc {get;set;}
    public List<LinhaContaCorrente> linhas {get;set;}
    public Decimal saldoCliente {get;set;}
    public boolean emFalta {get;set;}
    public c_ViewerContaCorrente(ApexPages.StandardController stdCtrl){
        this.acc = [select Id,Numero_de_cliente__c from Account where Id = :stdCtrl.getId()];
        emFalta = false;
    }
    
    public void init(){
        try{
            emFalta = false;
            if(acc.Numero_de_cliente__c != null && acc.Numero_de_cliente__c.isNumeric()){
                saldoCliente = IntegratorClientes.consultaSaldoCliente(Integer.valueOf(acc.Numero_de_cliente__c));
                clientStricker.ArrayOfContaCorrenteCliente result = Integrator.consultaLstContaCorrente(Long.valueOf(acc.Numero_de_cliente__c));
                linhas = new List<LinhaContaCorrente>();
                if(result.ContaCorrenteCliente != null){
                    system.debug(result.ContaCorrenteCliente.size());
                    for(clientStricker.ContaCorrenteCliente ccc : result.ContaCorrenteCliente){
                        linhas.add(new LinhaContaCorrente(ccc));
                        if(linhas.size() == 1500) break;
                    }
                }
                result = null;
            }
        }
        catch(System.CalloutException ec) { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ligacao_insucesso));
        }
        Catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ocorreu_um_erro));
        }
    }
    public void mostrarEmFalta(){
        try{
            emFalta = !emFalta;
            if(linhas != null){
                clientStricker.ArrayOfContaCorrenteCliente request = Integrator.consultaLstContaCorrente(Long.valueOf(acc.Numero_de_cliente__c));
                List<LinhaContaCorrente> result = new List<LinhaContaCorrente>();
                if(request.ContaCorrenteCliente != null){
                    for(clientStricker.ContaCorrenteCliente aux : request.ContaCorrenteCliente){
                        LinhaContaCorrente ccc = new LinhaContaCorrente(aux);
                        if(ccc.deb != 0.0){
                            if(ccc.deb_reg != ccc.deb){
                                result.add(ccc);
                            }
                        }else if(ccc.deb_moe != 0.0){
                            if(ccc.deb_moe_reg != ccc.deb_moe){
                                result.add(ccc);
                            }
                        }else if(ccc.cred != 0.0){
                            if(ccc.cred_reg_eur != ccc.cred){
                                result.add(ccc);
                            }
                        }else if(ccc.cred_moe != 0.0){
                            if(ccc.cred_reg != ccc.cred_moe){
                                result.add(ccc);
                            }
                        }
                    }
                }
                if(!result.isEmpty()){
                    linhas.clear();
                    linhas.addAll(result);
                }
            }
        }
        catch(System.CalloutException ec) { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ligacao_insucesso));
        }
        Catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ocorreu_um_erro));
        }
    } 
    
    public class LinhaContaCorrente{
        //public Long Numero_de_cliente_xc {get;set;}
        public Decimal cred{get;set;}
        public Decimal cred_moe{get;set;}
        public Decimal cred_reg{get;set;}
        public Decimal cred_reg_eur{get;set;}
        public DateTime dat{get;set;}
        public Decimal deb{get;set;}
        public Decimal deb_moe{get;set;}
        public Decimal deb_moe_reg{get;set;}
        public Decimal deb_reg{get;set;}
        public String descr{get;set;}
        public String doc{get;set;}
        public String moe{get;set;}
        public Decimal ndoc{get;set;}
        public DateTime dat_venc{get;set;}
        //public String ftstamp{get;set;}
        
        public LinhaContaCorrente(clientStricker.ContaCorrenteCliente ccc){
            //Numero_de_cliente_xc = ccc.Numero_de_cliente_xc;
            cred = ccc.Credito_xc;
            cred_moe = ccc.Credito_moeda_xc;
            cred_reg = ccc.Credito_regularizado_xc;
            cred_reg_eur = ccc.Credito_regularizado_euros;
            dat = ccc.Data_xc;
            deb = ccc.Debito_xc;
            deb_moe = ccc.Debito_moeda_xc;
            deb_moe_reg = ccc.Debito_moeda_regularizado_xc;
            deb_reg = ccc.Debito_regularizado_xc;
            descr = ccc.Descricao_xc;
            doc = ccc.Documento_xc;
            moe = ccc.CurrencyIsoCode;
            ndoc = ccc.Numero_de_documento_xc;
            dat_venc = ccc.Vencimento_xc;
            //ftstamp = ccc.ftstamp;
        }
    }
}