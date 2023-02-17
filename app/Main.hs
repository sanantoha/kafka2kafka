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
parse xs = do
  let config = parseConfig (Config { bootstrapConsumer = "", bootstrapProducer = "", topicConsumer = "", topicProducer = "" }) xs
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
                                        | otherwise = parseConfig config xs
  
  
usage = putStrLn "Usage: [-vh] -bc kafka_consumer_bootstrap:9092 -bp kafka_producer_bootstrap:9092 -tc topic_consumer -tp topic_producer"

version = putStrLn "0.001"
exit = exitWith ExitSuccess

