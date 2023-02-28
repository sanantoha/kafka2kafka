module Kafka2kafka.Entity.Config (
    Config(..), 
    ConfigCerts(..)
) where


data Config = Config {
  bootstrapConsumer :: String,
  bootstrapProducer :: String,  
  topicConsumer :: String,
  topicProducer :: String,
  configCertsConsumer :: Maybe ConfigCerts,
  configCertsProducer :: Maybe ConfigCerts
} deriving Show

data ConfigCerts = ConfigCerts {
    protocol :: String,
    caLocation :: String,
    certificateLocation :: String,
    keyLocation :: String
} deriving Show