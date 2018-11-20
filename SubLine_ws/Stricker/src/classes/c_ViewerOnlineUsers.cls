public class c_ViewerOnlineUsers {
    public Account acc {get;set;}
    public List<ViewerLogIn> linhas {get;set;}
    public String user {get;set;}
    public c_ViewerOnlineUsers(ApexPages.StandardController stdCtrl){
        this.acc = [select Id,Numero_de_cliente__c from Account where Id = :stdCtrl.getId()];        
    }
    
    public void init(){
        try{
            linhas = IntegratorSite.onlineHistory(Long.valueOf(acc.Numero_de_cliente__c));
        }
        catch(System.CalloutException ec) { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ligacao_insucesso));
        }
        Catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ocorreu_um_erro));
        }
    }
    
    public class ViewerLogIn{
        public Decimal NumeroLogins {get;set;}
        public String Cliente {get;set;}
        public String Empresa_xc {get;set;}
        public DateTime dataLogin {get;set;}
        
        public ViewerLogIn(){}
        
        public ViewerLogIn(clientStrickerSite.viewerLogins viewerLog){
            NumeroLogins = viewerLog.NumeroLogins;
            Cliente = viewerLog.Cliente;
            Empresa_xc = viewerLog.Empresa_xc;
            dataLogin = viewerLog.dataLogin;
        }
    }
}