{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Network (connectTo, PortID(..))
import Network.Starling

import Control.Exception
import Control.Concurrent (threadDelay)
import Control.Monad (void)
import System.Process
import Test.HUnit

--port :: PortNumber
port = 11222
host :: String
host = "localhost"

withConnection :: (Connection -> IO c) -> IO c
withConnection = bracket connect disconnect where
    -- hSetBuffering h NoBuffering
  connect = connectTo host ( PortNumber port) >>= open
  disconnect = close

setGetTest :: Test
setGetTest = TestCase $ withConnection $ \con -> do
    let key = "foo"
        val = 3 :: Int
    set con 0 key val
    mrval <- get con key
    case mrval of
      Nothing -> assertFailure "'foo' not found just after setting it"
      Just rval  -> assertEqual "foo value" val rval

expirationTest :: Test
expirationTest = TestCase $ withConnection $ \con -> do
    let key = "foo"
        val = 3 :: Int
        exp = 1 :: Int
    set con (fromIntegral exp) key val
    threadDelay $ exp*1000000+50000
    (mrval::(Maybe Int)) <- get con key
    assertEqual "foo value" mrval Nothing

main :: IO ()
main = void (bracket upDaemon downDaemon runTests) where
  upDaemon   = do m <- runCommand $ "memcached -p " ++ show port
                  threadDelay 50000  -- give it time to start up and bind.
                  return m
  downDaemon = terminateProcess
  runTests _ = runTestTT $ TestList [setGetTest, expirationTest]

-- vim: set ts=2 sw=2 et :
