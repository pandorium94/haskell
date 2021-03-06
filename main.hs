import Yesod
import Database.Persist.Postgresql
import Data.Text as T hiding (replace,take,zipWith)
import Control.Monad.Logger (runStdoutLoggingT)
import Data.Time.Calendar
             
data App = App{connPool :: ConnectionPool}

instance Yesod App

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|

Paciente json
    nome Text
    idade Int
    cpf Text -- sqltype=varchar(11)
   deriving Show
Prontuario json
    pacienteId PacienteId
    medicoId MedicoId
    hospitalId HospitalId
    dat Day
    deriving Show
ProntuarioEnfermidade json
    prontuarioId ProntuarioId
    enfermidadeId EnfermidadeId  -- possivel datatype enum
    deriving Show
Enfermidade json
   cid Text
   nome Text
   deriving Show
Medico json
    nome Text
    idade Int
    cpf Text -- sqltype=varchar(11)
    crm Text -- sqltype=varchar(5) -- só existem 400 mil médicos atuando no brasil
    especializacao Text
    deriving Show
MedicoHospital json
    medicoId MedicoId
    hospitalId HospitalId
    deriving Show
Hospital json
    nome Text
    cnpj Text
    deriving Show
|]

--yesod despatcher
mkYesod "App" [parseRoutes| 
/                                                   HomeR                       GET
        
!/paciente/#PacienteId                              PacienteBuscarR             GET 
!/paciente/buscar-nome/#Text                        PacienteBuscarNomeR         GET
/paciente/listarPacientes                           PacienteListarR             GET
/paciente/inserir                                   PacienteInserirR            POST
/paciente/alterar/#PacienteId                       PacienteAlterarR            PUT
/paciente/remover/#PacienteId                       PacienteRemoverR            DELETE --
        
!/medico/#MedicoId                                  MedicoBuscarR               GET
!/medico/nome/#Text                                 MedicoBuscarNomeR           GET
/medico/listarMedicos                               MedicosListarR              GET
/medico/inserir                                     MedicoInserirR              POST
/medico/alterar/#MedicoId                           MedicoAlterarR              PUT
/medico/especializacao/#Text                        MedicoBuscarEspecR          GET
/medico/hospitais/#MedicoId                         MedicoBuscarHospR           GET  --

!/hospital/#HospitalId                              HospitalBuscarR             GET
/hospital/nome/#Text                                HospitalBuscarNomeR         GET
/hospital/listarHospitais                           HospitalListarR             GET
/hospital/inserir                                   HospitalInserirR            POST
/hospital/alterar/#HospitalId                       HospitalAlterarR            PUT
/hospital/buscar-medicos/#HospitalId                HospitalBuscarMedicoR       GET --

!/enfermidade/#EnfermidadeId                        EnfermidadeBuscarR          GET
/enfermidade/listarEnfermidades                     EnfermidadesListarR         GET
/enfermidade/inserir                                EnfermidadeInserirR         POST
/enfermidade/buscar/#Text                           EnfermidadeBuscarNomeR      GET

!/prontuario/#ProntuarioId                          ProntuarioBuscarR           GET
/prontuario/listarProntuarios                       ProntuariosListarR          GET
/prontuario/inserir                                 ProntuarioInserirR          POST
/prontuario/buscar-paciente/#PacienteId             ProntuarioBuscarPacienteR   GET   --                         
/prontuario/buscar-medico/#MedicoId                 ProntuarioBuscarMedicoR     GET   --
/prontuario/buscar-enfermidade/#EnfermidadeId       ProntuarioBuscarEnfermR     GET   --

|]

-- HANDLERS

-- ========= PACIENTE
getHomeR :: Handler ()
getHomeR = undefined
                                    --handler vai definir qual mimetype 
getPacienteBuscarR :: PacienteId -> Handler Value
getPacienteBuscarR pid = do
    paciente <- runDB $ get404 pid
    sendResponse ( object [pack "resp" .= toJSON paciente ])
    
getPacienteBuscarNomeR :: Text -> Handler Value
getPacienteBuscarNomeR pnome = do
    npaciente <- runDB $ selectList [Filter PacienteNome (Left $ T.concat ["%", pnome, "%"]) (BackendSpecificFilter "ILIKE")] []
    sendResponse ( object [pack "resp" .= toJSON npaciente ])

getPacienteListarR :: Handler Value
getPacienteListarR = do
    paciente <- runDB $ selectList [] [Asc PacienteNome]
    sendResponse ( object [pack "resp" .= toJSON paciente ])

postPacienteInserirR :: Handler ()
postPacienteInserirR = do
    paciente <- requireJsonBody :: Handler Paciente
    pid <- runDB $ insert paciente
    sendResponse ( object [pack "resp" .= pack "Paciente inserido com sucesso" ])
    

putPacienteAlterarR :: PacienteId -> Handler ()
putPacienteAlterarR pid = do
    paciente <- requireJsonBody :: Handler Paciente
    runDB $ replace pid paciente
    sendResponse ( object [pack "resp" .= pack "Paciente atualizado com sucesso" ])

deletePacienteRemoverR :: PacienteId -> Handler ()
deletePacienteRemoverR pid = do
    runDB $ delete pid
    sendResponse (object [pack "resp" .= pack "Paciente Deletado com sucesso"] )

---------------------------------------------------------------------------------------------
-- ========= Medico

getMedicoBuscarR :: MedicoId -> Handler Value
getMedicoBuscarR mid = do
    medico <- runDB $ get404 mid
    sendResponse ( object [pack "resp" .= toJSON medico ])

getMedicoBuscarNomeR :: Text -> Handler Value
getMedicoBuscarNomeR mednome = do
    medico <- runDB $ selectList [Filter MedicoNome (Left $ T.concat ["%", mednome, "%"]) (BackendSpecificFilter "ILIKE")] []
    sendResponse ( object [pack "resp" .= toJSON medico ])

getMedicosListarR :: Handler Value
getMedicosListarR = do
    medico <- runDB $ selectList [] [Asc MedicoNome]
    sendResponse ( object [pack "resp" .= toJSON medico ])
    
postMedicoInserirR :: Handler ()
postMedicoInserirR = do
    medico <- requireJsonBody :: Handler Medico
    mid <- runDB $ insert medico
    sendResponse ( object [pack "resp" .= pack "Medico inserido com sucesso" ])
    
putMedicoAlterarR :: MedicoId -> Handler ()
putMedicoAlterarR mid = do
    medico <- requireJsonBody :: Handler Medico
    runDB $ replace mid medico
    sendResponse ( object [pack "resp" .= pack "Medico atualizado com sucesso" ])
    
getMedicoBuscarEspecR :: Text -> Handler Value
getMedicoBuscarEspecR espnome = do
    especializacao <- runDB $ selectList [Filter MedicoEspecializacao (Left $ T.concat ["%", espnome, "%"]) (BackendSpecificFilter "ILIKE")] []
    sendResponse ( object [pack "resp" .= toJSON especializacao ])

---------------------------------------------------------------------------------------------
-- =========HOSPITAL

getHospitalBuscarR :: HospitalId -> Handler Value
getHospitalBuscarR hid = do
    hospital <- runDB $ get404 hid
    sendResponse ( object [pack "resp" .= toJSON hospital ])
    
getHospitalBuscarNomeR :: Text -> Handler Value
getHospitalBuscarNomeR hnome = do
    nome <- runDB $ selectList [Filter HospitalNome (Left $ T.concat ["%", hnome, "%"]) (BackendSpecificFilter "ILIKE")] []
    sendResponse ( object [pack "resp" .= toJSON nome ])    

getHospitalListarR :: Handler Value
getHospitalListarR = do
    hospital <- runDB $ selectList [] [Asc HospitalNome]
    sendResponse ( object [pack "resp" .= toJSON hospital ])

postHospitalInserirR :: Handler ()
postHospitalInserirR = do
    hospital <- requireJsonBody :: Handler Hospital
    hid <- runDB $ insert hospital
    sendResponse ( object [pack "resp" .= pack "Hospital inserido com sucesso" ])
    
putHospitalAlterarR :: HospitalId -> Handler ()
putHospitalAlterarR hid = do
    hospital <- requireJsonBody :: Handler Hospital
    runDB $ replace hid hospital
    sendResponse ( object [pack "resp" .= pack "Hospital atualizado com sucesso" ])
    
---------------------------------------------------------------------------------------------
-- =========PRONTUARIO

getProntuarioBuscarR :: ProntuarioId -> Handler Value
getProntuarioBuscarR prid = do
    prontuario <- runDB $ get404 prid
    sendResponse ( object [pack "resp" .= toJSON prontuario ])

getProntuariosListarR :: Handler Value
getProntuariosListarR = do
    prontuario <- runDB $ selectList [] [Asc ProntuarioId]
    sendResponse ( object [pack "resp" .= toJSON prontuario ])

postProntuarioInserirR :: Handler ()
postProntuarioInserirR = do
    (prontuario, eid) <- requireJsonBody :: Handler (Prontuario, EnfermidadeId)
    peid <- runDB $ do
        pid <- insert prontuario
        insert $ ProntuarioEnfermidade pid eid
    sendResponse ( object [pack "resp" .= pack "Prontuario inserido com sucesso" ])
    
---------------------------------------------------------------------------------------------
-- ========= ENFERMIDADE

getEnfermidadeBuscarR :: EnfermidadeId -> Handler Value
getEnfermidadeBuscarR eid = do
    enfermidade <- runDB $ get404 eid
    sendResponse ( object [pack "resp" .= toJSON enfermidade ])    
    
getEnfermidadesListarR :: Handler Value
getEnfermidadesListarR = do
    enfermidade <- runDB $ selectList [] [Asc EnfermidadeId]
    sendResponse ( object [pack "resp" .= toJSON enfermidade ])

postEnfermidadeInserirR :: Handler ()
postEnfermidadeInserirR = do
    enfermidade <- requireJsonBody :: Handler Enfermidade
    eid <- runDB $ insert enfermidade
    sendResponse ( object [pack "resp" .= pack "Enfermidade inserida com sucesso" ])    

getEnfermidadeBuscarNomeR :: Text -> Handler Value
getEnfermidadeBuscarNomeR enome = do
    enfermidades <- runDB $ selectList [Filter EnfermidadeNome (Left $ T.concat ["%", enome, "%"]) (BackendSpecificFilter "ILIKE")] []
-- (rawSql "select ?? from Enfermidade where nome ilike '%?%'" [toPersistText enome]) :: [Entity Enfermidade]
    sendResponse ( object [pack "resp" .= toJSON enfermidades ])

-- ===================================== REGRAS DE NEGOCIO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

getMedicoBuscarHospR :: MedicoId -> Handler Value
getMedicoBuscarHospR mid = do
    hospitaisDoMedicoId <- runDB $ selectList [MedicoHospitalMedicoId ==. mid] []  -- [Entity MedicoHospital]
    hospitaisDoMedico <- runDB $ mapM (\ medicoHospital -> get404 (medicoHospitalHospitalId $ entityVal medicoHospital)) hospitaisDoMedicoId -- [Entity Hospital]
    medico <- runDB $ get404 mid                                                     -- (Entity Medico)
    let nomeMedico = medicoNome medico                                               -- Extrai o nome do médico para uma nomeação
    let respostaObject = object[ nomeMedico .= fmap toJSON hospitaisDoMedico]        -- Monta o object de resposta
    sendResponse (object [pack "resp" .= respostaObject ])                           -- envia a resposta para o cliente

getHospitalBuscarMedicoR :: HospitalId -> Handler Value
getHospitalBuscarMedicoR hid = do
    medicosDoHospitalId <- runDB $ selectList [MedicoHospitalHospitalId ==. hid] []  
    medicosDoHospital <- runDB $ mapM (\ hospitalMedico -> get404 (medicoHospitalMedicoId $ entityVal hospitalMedico)) medicosDoHospitalId
    hospital <- runDB $ get404 hid 
    let nomeHospital   = hospitalNome hospital
        respostaObject = object[ nomeHospital .= fmap toJSON medicosDoHospital] 
    sendResponse (object [pack "resp" .= respostaObject ])

getProntuarioBuscarPacienteR :: PacienteId -> Handler Value
getProntuarioBuscarPacienteR  pid = do
    prontuariosPaciente <- runDB $ selectList [ProntuarioPacienteId ==. pid] []
    paciente <- runDB $ get404 pid
    let nomePaciente = (unpack.pacienteNome) paciente
    sendResponse (object [pack "resp" .= (object[pack nomePaciente .= (fmap toJSON prontuariosPaciente)]) ])

getProntuarioBuscarMedicoR :: MedicoId -> Handler Value
getProntuarioBuscarMedicoR mid = do
    prontuariosMedico <- runDB $ selectList [ProntuarioMedicoId ==. mid] []
    medico <- runDB $ get404 mid
    let nomePaciente = (unpack.medicoNome) medico
    sendResponse (object[pack "resp" .= (object[pack nomePaciente .= (fmap toJSON prontuariosMedico)]) ])

getProntuarioBuscarEnfermR :: EnfermidadeId -> Handler Value
getProntuarioBuscarEnfermR enfid = do
    prontuariosEnfermidadeId <- runDB $ selectList [ProntuarioEnfermidadeEnfermidadeId ==. enfid ] []
    prontuarios <- runDB $ mapM (\ prontuarioEnfermidade -> (get404.prontuarioEnfermidadeProntuarioId.entityVal) prontuarioEnfermidade ) prontuariosEnfermidadeId
    enfermidade <- runDB $ get404 enfid
    let nome = enfermidadeNome enfermidade
    let resposta = object[ nome .= fmap toJSON prontuarios] 
    sendResponse (object[pack "resp" .= resposta ])
    
-- Super!
foo :: Handler Value
foo = undefined {-do
    xs <- runDB $ (rawSql (pack $ "SELECT ??, ??, ?? FROM produtoz  \ 
        \ INNER JOIN clientes_produtos ON produtoz.id=clientes_produtos.prid \ 
        \ INNER JOIN clientes ON  clientes.id=clientes_produtos.clid \
        \ WHERE clientes_produtos.clid = " ++ (show $ fromSqlKey pid)) []) :: Handler [(Entity Produtoz,Entity ClientesProdutos,Entity Clientes)]
    sendResponse (object [pack "data" .= fmap (toJSON . (\(p,_,_) -> p)) xs])

-}

validarCPf :: [Int] -> Bool
validarCPf cpf =
    let -- calcula primeiro digito
        digitos1 = take 9 cpf
        expr1 = mod (sum (zipWith (*) digitos1 [10,9..])) 11
        dv1 = if expr1 < 2 then 0 else 11-expr1
        -- calcula segundo digito
        digitos2 = digitos1 ++ [dv1]
        expr2 = mod (sum (zipWith (*) digitos2 [11,10..])) 11
        dv2 = if expr2 < 2 then 0 else 11-expr2
        
    in dv1 == cpf !! 9 && dv2 == cpf !! 10

---------------------------------------------------------------------------------------------

instance YesodPersist App where
   type YesodPersistBackend App = SqlBackend
   runDB f = do
       master <- getYesod
       let pool = connPool master
       runSqlPool f pool
       
---------------------------------------------------------------------------------------------

connStr = "dbname=dbs10j40oj2r50 host=ec2-54-225-95-99.compute-1.amazonaws.com user=ywzfzssfskwcju password=QOoBT4kER9KgAod70niCY3T6tB port=5432"

main::IO()
main = runStdoutLoggingT $ withPostgresqlPool connStr 10 $ \pool -> liftIO $ do 
       runSqlPersistMPool (runMigration migrateAll) pool
       warp 8081 (App pool)