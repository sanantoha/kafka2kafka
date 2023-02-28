{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE FlexibleContexts #-}


module Kafka2kafka.Internal.Util (
    mapConfigCerts,
    consumerProps,
    consumerSub,
    producerProps,
    processMessages,
    sendMessageSync,
    mkMessage
) where

import Kafka2kafka.Entity.Config

import qualified Data.Text as T
import qualified Data.Map as Map
import Data.ByteString         (ByteString)
import Data.ByteString.Char8   (pack, unpack)
import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Control.Monad.IO.Class  (MonadIO(..))
import qualified Kafka.Producer as P
import Kafka.Producer
import qualified Kafka.Consumer as C
import Kafka.Consumer


mapConfigCerts :: ConfigCerts -> Map.Map T.Text T.Text
mapConfigCerts (ConfigCerts { 
                                    protocol = prot, 
                                    caLocation = caLoc, 
                                    certificateLocation = certLoc, 
                                    keyLocation = keyLoc 
                                }) = Map.fromList [
                            ("security.protocol", T.pack prot),
                            ("ssl.ca.location", T.pack caLoc ),
                            ("ssl.certificate.location", T.pack certLoc ),
                            ("ssl.key.location", T.pack keyLoc )
                        ]


-- Global consumer properties
consumerProps :: String -> ConsumerProperties -> ConsumerProperties
consumerProps bc extraConsumerProps = C.brokersList [BrokerAddress . T.pack $ bc]
                                    <> groupId "kafka2kafka0001"
                                    <> noAutoCommit
                                    <> C.logLevel KafkaLogInfo
                                    <> extraConsumerProps
                        


-- Subscription to topics
consumerSub :: String -> Subscription
consumerSub topic = topics [TopicName . T.pack $ topic]
                <> offsetReset Earliest

-- Global producer properties
producerProps :: String -> ProducerProperties -> ProducerProperties
producerProps bp extraProducerProps = P.brokersList [BrokerAddress . T.pack $ bp]
                                    <> P.logLevel KafkaLogDebug        
                                    <> extraProducerProps





processMessages :: String -> KafkaProducer -> KafkaConsumer -> IO (Either KafkaError ())
processMessages topicNameProducer producer consumer = do
    mapM_ (\_ -> do
                    msg <- pollMessage consumer (Timeout 1000)
                    let parsedMsg = parseMsg <$> msg
                    handleMsg parsedMsg                                                
        ) [0 :: Integer ..]
    return $ Right ()

    where parseMsg consumerRecord = let key = crKey consumerRecord
                                        message = crValue consumerRecord
                                        headers = fmap (\(k, v) -> (unpack k, unpack v)) . headersToList . crHeaders $ consumerRecord
                                    in (headers, maybe "" unpack key, maybe "" unpack message)

          handleMsg (Left (KafkaResponseError _)) = putStrLn "no msgs"
          handleMsg (Left err) = putStrLn $ show err 
          handleMsg (Right (headers, key, value)) = do
                        putStrLn $ "Message: headers=" <> show headers <> "\n         key=" <> key <> " value=" <> value
                        let record = mkMessage topicNameProducer headers (Just $ pack key) (Just $ pack value)
                        res <- sendMessageSync producer record
                        putStrLn . show $ res
                        handleSentMsg res

          handleSentMsg (Right _) = do
                        err <- commitAllOffsets OffsetCommit consumer
                        putStrLn $ "Offsets: " <> maybe "Committed." show err
          handleSentMsg (Left err) =  putStrLn . show $ err



sendMessageSync :: MonadIO m
                => KafkaProducer
                -> ProducerRecord
                -> m (Either KafkaError Offset)
sendMessageSync producer record = liftIO $ do
  -- Create an empty MVar:
  var <- newEmptyMVar

  -- Produce the message and use the callback to put the delivery report in the
  -- MVar:
  res <- produceMessage' producer record (putMVar var)

  case res of
    Left (ImmediateError err) ->
      pure (Left err)
    Right () -> do
      -- Flush producer queue to make sure you don't get stuck waiting for the
      -- message to send:
      flushProducer producer

      -- Wait for the message's delivery report and map accordingly:
      takeMVar var >>= return . \case
        DeliverySuccess _ offset -> Right offset
        DeliveryFailure _ err    -> Left err
        NoMessageError err       -> Left err


mkMessage :: String -> [(String, String)] -> Maybe ByteString -> Maybe ByteString -> ProducerRecord
mkMessage t h k v = ProducerRecord
                  { prTopic = TopicName . T.pack $ t
                  , prPartition = UnassignedPartition
                  , prKey = k
                  , prValue = v
                  , prHeaders = headersFromList . fmap (\(key, val) -> (pack key, pack val)) $ h
                  }                        