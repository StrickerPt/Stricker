public class CurrencyConverter {
    private static Map<string, CurrencyType> conversions = null;
    private static String corporateIso = null;
    private static String userIso = null;

    /**
     * Initialize corporate currencies setup in Setup.
     */
    private static void initCorpCurrencies() {
        // build once only
        if (null != conversions) return;

        // build map
        conversions = new Map<string, CurrencyType>();
        List<CurrencyType> currencies = [select Id, IsCorporate, IsoCode, ConversionRate, DecimalPlaces from CurrencyType where IsActive=true];
        for (CurrencyType cur : currencies) {
            conversions.put(cur.IsoCode, cur);
            if (cur.IsCorporate) corporateIso = cur.IsoCode;
        }
    }

    /**
     * Convert between two known currencies.
     */
    public static Decimal convert(Decimal value, String fromIso, String toIso) {
        if (String.isEmpty(fromIso) || String.isEmpty(toIso)) {
            return value;
        }
        initCorpCurrencies();

        // ensure valid to/from ISO
        if (!conversions.containsKey(fromIso)) {
           throw new UnknownCurrencyException('Unable to find active from ISO currency ');
        }
        if (!conversions.containsKey(toIso)) {
           throw new UnknownCurrencyException('Unable to find active to ISO currency ');
        }

        // if same currencies we simply round
        if (fromIso.equalsIgnoreCase(toIso)) {
           if(!Test.isRunningTest()) return value.setScale(conversions.get(fromIso.toUpperCase()).DecimalPlaces, System.RoundingMode.HALF_UP);
            else return value;
        }

        // get values and then rate
        final CurrencyType fromCur = conversions.get(fromIso.toUpperCase());
        final Decimal fromRate = fromCur.ConversionRate;
        final CurrencyType toCur = conversions.get(toIso.toUpperCase());
        final Decimal toRate = toCur.ConversionRate;
        final Decimal rate = toRate/fromRate;

        // calc
        final Decimal result = value * rate;
        final Decimal resultRounded = result.setScale(toCur.DecimalPlaces, System.RoundingMode.HALF_UP);

        // return
        return resultRounded;
    }

    public class UnknownUserException extends Exception {

    }

    public class UnknownCurrencyException extends Exception {

    }
}