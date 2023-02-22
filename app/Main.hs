module Main (main) where

import System.Environment
import System.Exit
import Lib

main :: IO ()
main = do
  config <- getArgs >>= parse
  run config
  putStrLn "Exit"



parse :: [String] -> IO Config
parse ["-h"] = usage >> exit
parse ["-v"] = version >> exit
parse xss = do
  let config = parseConfig (Config 
                              { 
                                bootstrapConsumer = "", 
                                bootstrapProducer = "", 
                                topicConsumer = "", 
                                topicProducer = "",
                                configCertsConsumer = Nothing,
                                configCertsProducer = Nothing
                              }
                            ) xss
  case config of
      c@Config { bootstrapConsumer = bc, bootstrapProducer = bp, topicConsumer = tc, topicProducer = tp } -> 
          if bc == "" || bp == "" || tc == "" || tp == "" then usage >> exit
          else putStrLn $ show c
  return config
        
      where parseConfig config [] = config
            parseConfig config [_] = config
            parseConfig config (x:y:xs) | x == "-bc" = parseConfig config { bootstrapConsumer = y } xs
                                        | x == "-bp" = parseConfig config { bootstrapProducer = y } xs
                                        | x == "-tc" = parseConfig config { topicConsumer = y } xs
                                        | x == "-tp" = parseConfig config { topicProducer = y } xs
                                        | x == "-pc" = applyCertFuncConsumer addProtocolToConfigCerts config y xs
                                        | x == "-calc" = applyCertFuncConsumer addCaLocation config y xs
                                        | x == "-certlc" = applyCertFuncConsumer addCertificateLocation config y xs
                                        | x == "-keylc" = applyCertFuncConsumer addKeyLocation config y xs
                                        | x == "-pp" = applyCertFuncProducer addProtocolToConfigCerts config y xs
                                        | x == "-calp" = applyCertFuncProducer addCaLocation config y xs
                                        | x == "-certlp" = applyCertFuncProducer addCertificateLocation config y xs
                                        | x == "-keylp" = applyCertFuncProducer addKeyLocation config y xs
                                        | otherwise = parseConfig config xs

            defaultConfigCerts = ConfigCerts { protocol = "", caLocation = "", certificateLocation = "", keyLocation = "" }            

            applyCertFuncConsumer f config val xs = do
                                        let configCerts = f (configCertsConsumer config) val
                                        parseConfig config { configCertsConsumer = Just configCerts } xs

            applyCertFuncProducer f config val xs = do
                                        let configCerts = f (configCertsProducer config) val
                                        parseConfig config { configCertsProducer = Just configCerts } xs

            addProtocolToConfigCerts configCerts val = maybe (defaultConfigCerts { protocol = val }) (\cc -> cc { protocol = val }) configCerts

            addCaLocation configCerts val = maybe (defaultConfigCerts { caLocation = val }) (\cc -> cc { caLocation = val }) configCerts

            addCertificateLocation configCerts val = maybe (defaultConfigCerts { certificateLocation = val }) (\cc -> cc { certificateLocation = val }) configCerts

            addKeyLocation configCerts val = maybe (defaultConfigCerts { keyLocation = val } ) (\cc -> cc { keyLocation = val })  configCerts

            

            
  
  
usage :: IO ()
usage = putStrLn "Usage: [-vh] -bc kafka_consumer_bootstrap:9092 -bp kafka_producer_bootstrap:9092 -tc topic_consumer -tp topic_producer"

version :: IO ()
version = putStrLn "0.001"

exit :: IO a
exit = exitWith ExitSuccess

