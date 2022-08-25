

import java.io.FileInputStream;
import java.math.BigInteger;
import java.security.KeyStore;
import java.security.KeyStoreException;
import javax.crypto.SecretKey;



public class JKSExtractSKE {
  public static void main(String[] args) throws Exception {
    if( args.length < 4){
        System.out.println( "ERROR: java JKSExtractSKE <vault> <alias> <storepass> <keypass>" );

        System.exit(1);
    }
    final String fileName = args[0];
    final String alias = args[1];
    final char[] storepass = args[2].toCharArray();
    final char[] keypass = args[3].toCharArray();

    KeyStore ks = KeyStore.getInstance("JCEKS");

    try (FileInputStream fis = new FileInputStream(fileName)) {

        ks.load( fis, storepass );
        SecretKey secretKey = (SecretKey)ks.getKey( alias, keypass );

        System.out.println( new BigInteger(1, secretKey.getEncoded()).toString(16) );
    }
  }
}
