public class WrapperCalculoTransportadora {
    public static List<String> fields = new List<String>{'CTT','TNT_Economy','Dachser', 'TNT_Express','TNTEconomy','TNTExpress'};
	public Dados CTT;
	public Dados TNT_Economy;
	public Dados TNT_Express;
	public Dados Dachser;
    
    public Dados get(String field){
        if(field == 'CTT')
            return CTT;
        else if(field == 'TNT_Economy')
            return TNT_Economy;
        else if(field == 'TNT_Express')
            return TNT_Express;
        else if(field == 'TNTEconomy')
            return TNT_Economy;
        else if(field == 'TNTExpress')
            return TNT_Express;
        else if(field == 'Dachser')
            return Dachser;
        return null;
    }
    
    public class Dados{
        
        public double valor_transporte;
        public double valor_despacho;
        public double valor_custo;
        public String duracao;
        public String moeda;
        public String peso;
        
    }
}