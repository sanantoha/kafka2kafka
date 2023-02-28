{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE FlexibleContexts #-}

module Lib(run) where

import Kafka2kafka.Internal.Util 
import Kafka2kafka.Entity.Config
import Control.Exception (bracket)
import qualified Kafka.Consumer as C
import qualified Kafka.Producer as P


run :: Config -> IO ()
run (Config { 
                bootstrapConsumer = bc, 
                bootstrapProducer = bp, 
                topicConsumer = tc, 
                topicProducer = tp,
                configCertsConsumer = ccc,
                configCertsProducer = ccp
            }) = do
        res <- bracket pk closeResources runHandler
        print res
        where 
            mkExtraProps f = maybe mempty f . fmap mapConfigCerts

            mkConsumer = C.newConsumer (consumerProps bc . mkExtraProps C.extraProps $ ccc) (consumerSub tc)

            mkProducer = P.newProducer (producerProps bp . mkExtraProps P.extraProps $ ccp)

            pk = (\p c -> (p, c)) <$> mkProducer <*> mkConsumer

            closeResources (pe, ce) = clProducer pe <> clConsumer ce

            clConsumer (Left err) = return (Left err)
            clConsumer (Right kc) = maybe (Right ()) Left <$> C.closeConsumer kc

            clProducer (Left err)     = return (Left err)
            clProducer (Right prod) = Right <$> P.closeProducer prod

            runHandler (_, Left err) = return (Left err)
            runHandler (Left err, _) = return (Left err)
            runHandler (Right p, Right k) = processMessages tp p k