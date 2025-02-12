# Definir a codificação de saída como UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Definição de cores
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# Caminho do arquivo de configuração
$STORAGE_FILE = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
$BACKUP_DIR = "$env:APPDATA\Cursor\User\globalStorage\backups"

# Verificar permissões de administrador
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "$RED[Erro]$NC Por favor, execute este script como administrador"
    Write-Host "Clique com o botão direito no script e selecione 'Executar como administrador'"
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Exibir Logo
Clear-Host
Write-Host @"

    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝

"@
Write-Host "$BLUE================================$NC"
Write-Host "$GREEN   Ferramenta de Modificação de ID do Cursor          $NC"
Write-Host "$YELLOW  Siga o canal【煎饼果子卷AI】 $NC"
Write-Host "$YELLOW  Junte-se para mais dicas sobre Cursor e conhecimento de IA (script gratuito, siga o canal para mais dicas e interação com especialistas)  $NC"
Write-Host "$YELLOW  [Aviso Importante] Esta ferramenta é gratuita, se for útil para você, siga o canal【煎饼果子卷AI】  $NC"
Write-Host "$BLUE================================$NC"
Write-Host ""

# Obter e exibir a versão do Cursor
function Get-CursorVersion {
    try {
        # Caminho principal de detecção
        $packagePath = "$env:LOCALAPPDATA\Programs\cursor\resources\app\package.json"
        
        if (Test-Path $packagePath) {
            $packageJson = Get-Content $packagePath -Raw | ConvertFrom-Json
            if ($packageJson.version) {
                Write-Host "$GREEN[Informação]$NC Versão do Cursor instalada: v$($packageJson.version)"
                return $packageJson.version
            }
        }

        # Caminho alternativo de detecção
        $altPath = "$env:LOCALAPPDATA\cursor\resources\app\package.json"
        if (Test-Path $altPath) {
            $packageJson = Get-Content $altPath -Raw | ConvertFrom-Json
            if ($packageJson.version) {
                Write-Host "$GREEN[Informação]$NC Versão do Cursor instalada: v$($packageJson.version)"
                return $packageJson.version
            }
        }

        Write-Host "$YELLOW[Aviso]$NC Não foi possível detectar a versão do Cursor"
        Write-Host "$YELLOW[Dica]$NC Certifique-se de que o Cursor está instalado corretamente"
        return $null
    }
    catch {
        Write-Host "$RED[Erro]$NC Falha ao obter a versão do Cursor: $_"
        return $null
    }
}

# Obter e exibir informações da versão
$cursorVersion = Get-CursorVersion
Write-Host ""

Write-Host "$YELLOW[Aviso Importante]$NC Versões 0.45.x (suportadas)"
Write-Host ""

# Verificar e fechar processos do Cursor
Write-Host "$GREEN[Informação]$NC Verificando processos do Cursor..."

function Get-ProcessDetails {
    param($processName)
    Write-Host "$BLUE[Debug]$NC Obtendo detalhes do processo $processName:"
    Get-WmiObject Win32_Process -Filter "name='$processName'" | 
        Select-Object ProcessId, ExecutablePath, CommandLine | 
        Format-List
}

# Definir número máximo de tentativas e tempo de espera
$MAX_RETRIES = 5
$WAIT_TIME = 1

# Fechar processos do Cursor
function Close-CursorProcess {
    param($processName)
    
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "$YELLOW[Aviso]$NC Processo $processName em execução"
        Get-ProcessDetails $processName
        
        Write-Host "$YELLOW[Aviso]$NC Tentando fechar $processName..."
        Stop-Process -Name $processName -Force
        
        $retryCount = 0
        while ($retryCount -lt $MAX_RETRIES) {
            $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if (-not $process) { break }
            
            $retryCount++
            if ($retryCount -ge $MAX_RETRIES) {
                Write-Host "$RED[Erro]$NC Não foi possível fechar $processName após $MAX_RETRIES tentativas"
                Get-ProcessDetails $processName
                Write-Host "$RED[Erro]$NC Feche o processo manualmente e tente novamente"
                Read-Host "Pressione Enter para sair"
                exit 1
            }
            Write-Host "$YELLOW[Aviso]$NC Aguardando o fechamento do processo, tentativa $retryCount/$MAX_RETRIES..."
            Start-Sleep -Seconds $WAIT_TIME
        }
        Write-Host "$GREEN[Informação]$NC $processName fechado com sucesso"
    }
}

# Fechar todos os processos do Cursor
Close-CursorProcess "Cursor"
Close-CursorProcess "cursor"

# Criar diretório de backup
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

# Fazer backup da configuração existente
if (Test-Path $STORAGE_FILE) {
    Write-Host "$GREEN[Informação]$NC Fazendo backup do arquivo de configuração..."
    $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $STORAGE_FILE "$BACKUP_DIR\$backupName"
}

# Gerar novo ID
Write-Host "$GREEN[Informação]$NC Gerando novo ID..."

# Função para gerar hexadecimal aleatório
function Get-RandomHex {
    param (
        [int]$length
    )
    
    $bytes = New-Object byte[] ($length)
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($bytes)
    $hexString = [System.BitConverter]::ToString($bytes) -replace '-',''
    $rng.Dispose()
    return $hexString
}

# Função para gerar ID padrão
function New-StandardMachineId {
    $template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    $result = $template -replace '[xy]', {
        param($match)
        $r = [Random]::new().Next(16)
        $v = if ($match.Value -eq "x") { $r } else { ($r -band 0x3) -bor 0x8 }
        return $v.ToString("x")
    }
    return $result
}

# Gerar novos IDs
$MAC_MACHINE_ID = New-StandardMachineId
$UUID = [System.Guid]::NewGuid().ToString()
$prefixBytes = [System.Text.Encoding]::UTF8.GetBytes("auth0|user_")
$prefixHex = -join ($prefixBytes | ForEach-Object { '{0:x2}' -f $_ })
$randomPart = Get-RandomHex -length 32
$MACHINE_ID = "$prefixHex$randomPart"
$SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"

# Verificar permissões de administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "$RED[Erro]$NC Execute este script como administrador"
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Atualizar MachineGuid no registro
function Update-MachineGuid {
    try {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
        if (-not (Test-Path $registryPath)) {
            throw "Caminho do registro não encontrado: $registryPath"
        }

        $currentGuid = Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction Stop
        if (-not $currentGuid) {
            throw "Não foi possível obter o MachineGuid atual"
        }

        $originalGuid = $currentGuid.MachineGuid
        Write-Host "$GREEN[Informação]$NC Valor atual do registro:"
        Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography" 
        Write-Host "    MachineGuid    REG_SZ    $originalGuid"

        if (-not (Test-Path $BACKUP_DIR)) {
            New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
        }

        $backupFile = "$BACKUP_DIR\MachineGuid_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        $backupResult = Start-Process "reg.exe" -ArgumentList "export", "`"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`"", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
        
        if ($backupResult.ExitCode -eq 0) {
            Write-Host "$GREEN[Informação]$NC Backup do registro salvo em: $backupFile"
        } else {
            Write-Host "$YELLOW[Aviso]$NC Falha ao criar backup, continuando..."
        }

        $newGuid = [System.Guid]::NewGuid().ToString()
        Set-ItemProperty -Path $registryPath -Name MachineGuid -Value $newGuid -Force -ErrorAction Stop
        
        $verifyGuid = (Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction Stop).MachineGuid
        if ($verifyGuid -ne $newGuid) {
            throw "Falha na verificação do registro: valor atualizado ($verifyGuid) não corresponde ao esperado ($newGuid)"
        }

        Write-Host "$GREEN[Informação]$NC Registro atualizado com sucesso:"
        Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography"
        Write-Host "    MachineGuid    REG_SZ    $newGuid"
        return $true
    }
    catch {
        Write-Host "$RED[Erro]$NC Falha na operação do registro: $($_.Exception.Message)"
        
        if ($backupFile -and (Test-Path $backupFile)) {
            Write-Host "$YELLOW[Restaurando]$NC Restaurando backup..."
            $restoreResult = Start-Process "reg.exe" -ArgumentList "import", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            if ($restoreResult.ExitCode -eq 0) {
                Write-Host "$GREEN[Restauração bem-sucedida]$NC Registro restaurado"
            } else {
                Write-Host "$RED[Erro]$NC Falha na restauração, restaure manualmente: $backupFile"
            }
        } else {
            Write-Host "$YELLOW[Aviso]$NC Backup não encontrado, restauração automática não disponível"
        }
        return $false
    }
}

# Atualizar arquivo de configuração
Write-Host "$GREEN[Informação]$NC Atualizando configuração..."

try {
    if (-not (Test-Path $STORAGE_FILE)) {
        Write-Host "$RED[Erro]$NC Arquivo de configuração não encontrado: $STORAGE_FILE"
        Write-Host "$YELLOW[Dica]$NC Execute o Cursor pelo menos uma vez antes de usar este script"
        Read-Host "Pressione Enter para sair"
        exit 1
    }

    try {
        $originalContent = Get-Content $STORAGE_FILE -Raw -Encoding UTF8
        $config = $originalContent | ConvertFrom-Json 

        $oldValues = @{
            'machineId' = $config.'telemetry.machineId'
            'macMachineId' = $config.'telemetry.macMachineId'
            'devDeviceId' = $config.'telemetry.devDeviceId'
            'sqmId' = $config.'telemetry.sqmId'
        }

        $config.'telemetry.machineId' = $MACHINE_ID
        $config.'telemetry.macMachineId' = $MAC_MACHINE_ID
        $config.'telemetry.devDeviceId' = $UUID
        $config.'telemetry.sqmId' = $SQM_ID

        $updatedJson = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($STORAGE_FILE), 
            $updatedJson, 
            [System.Text.Encoding]::UTF8
        )
        Write-Host "$GREEN[Informação]$NC Arquivo de configuração atualizado com sucesso"
    } catch {
        if ($originalContent) {
            [System.IO.File]::WriteAllText(
                [System.IO.Path]::GetFullPath($STORAGE_FILE), 
                $originalContent, 
                [System.Text.Encoding]::UTF8
            )
        }
        throw "Falha ao processar JSON: $_"
    }

    Update-MachineGuid

    Write-Host ""
    Write-Host "$GREEN[Informação]$NC Configuração atualizada:"
    Write-Host "$BLUE[Debug]$NC machineId: $MACHINE_ID"
    Write-Host "$BLUE[Debug]$NC macMachineId: $MAC_MACHINE_ID"
    Write-Host "$BLUE[Debug]$NC devDeviceId: $UUID"
    Write-Host "$BLUE[Debug]$NC sqmId: $SQM_ID"

    Write-Host ""
    Write-Host "$GREEN[Informação]$NC Estrutura de arquivos:"
    Write-Host "$BLUE$env:APPDATA\Cursor\User$NC"
    Write-Host "├── globalStorage"
    Write-Host "│   ├── storage.json (modificado)"
    Write-Host "│   └── backups"

    $backupFiles = Get-ChildItem "$BACKUP_DIR\*" -ErrorAction SilentlyContinue
    if ($backupFiles) {
        foreach ($file in $backupFiles) {
            Write-Host "│       └── $($file.Name)"
        }
    } else {
        Write-Host "│       └── (vazio)"
    }

    Write-Host ""
    Write-Host "$GREEN================================$NC"
    Write-Host "$YELLOW  Siga o canal【煎饼果子卷AI】 para mais dicas sobre Cursor e IA (script gratuito, siga o canal para mais dicas e interação com especialistas)  $NC"
    Write-Host "$GREEN================================$NC"
    Write-Host ""
    Write-Host "$GREEN[Informação]$NC Reinicie o Cursor para aplicar as novas configurações"
    Write-Host ""

    Write-Host ""
    Write-Host "$YELLOW[Pergunta]$NC Deseja desativar a atualização automática do Cursor?"
    Write-Host "0) Não - Manter configuração padrão (pressione Enter)"
    Write-Host "1) Sim - Desativar atualização automática"
    $choice = Read-Host "Digite a opção (0)"

    if ($choice -eq "1") {
        Write-Host ""
        Write-Host "$GREEN[Informação]$NC Processando atualização automática..."
        $updaterPath = "$env:LOCALAPPDATA\cursor-updater"

        function Show-ManualGuide {
            Write-Host ""
            Write-Host "$YELLOW[Aviso]$NC Falha na configuração automática, tente manualmente:"
            Write-Host "$YELLOWPassos para desativar a atualização manualmente:$NC"
            Write-Host "1. Abra o PowerShell como administrador"
            Write-Host "2. Copie e cole os seguintes comandos:"
            Write-Host "$BLUEComando 1 - Remover diretório existente (se existir):$NC"
            Write-Host "Remove-Item -Path `"$updaterPath`" -Force -Recurse -ErrorAction SilentlyContinue"
            Write-Host ""
            Write-Host "$BLUEComando 2 - Criar arquivo de bloqueio:$NC"
            Write-Host "New-Item -Path `"$updaterPath`" -ItemType File -Force | Out-Null"
            Write-Host ""
            Write-Host "$BLUEComando 3 - Definir atributo somente leitura:$NC"
            Write-Host "Set-ItemProperty -Path `"$updaterPath`" -Name IsReadOnly -Value `$true"
            Write-Host ""
            Write-Host "$BLUEComando 4 - Definir permissões (opcional):$NC"
            Write-Host "icacls `"$updaterPath`" /inheritance:r /grant:r `"`$($env:USERNAME):(R)`""
            Write-Host ""
            Write-Host "$YELLOWMétodo de verificação:$NC"
            Write-Host "1. Execute: Get-ItemProperty `"$updaterPath`""
            Write-Host "2. Verifique se IsReadOnly está como True"
            Write-Host "3. Execute: icacls `"$updaterPath`""
            Write-Host "4. Verifique se há apenas permissão de leitura"
            Write-Host ""
            Write-Host "$YELLOW[Dica]$NC Reinicie o Cursor após concluir"
        }

        try {
            if (Test-Path $updaterPath) {
                try {
                    Remove-Item -Path $updaterPath -Force -Recurse -ErrorAction Stop
                    Write-Host "$GREEN[Informação]$NC Diretório cursor-updater removido com sucesso"
                }
                catch {
                    Write-Host "$RED[Erro]$NC Falha ao remover diretório cursor-updater"
                    Show-ManualGuide
                    return
                }
            }

            try {
                New-Item -Path $updaterPath -ItemType File -Force -ErrorAction Stop | Out-Null
                Write-Host "$GREEN[Informação]$NC Arquivo de bloqueio criado com sucesso"
            }
            catch {
                Write-Host "$RED[Erro]$NC Falha ao criar arquivo de bloqueio"
                Show-ManualGuide
                return
            }

            try {
                Set-ItemProperty -Path $updaterPath -Name IsReadOnly -Value $true -ErrorAction Stop
                
                $result = Start-Process "icacls.exe" -ArgumentList "`"$updaterPath`" /inheritance:r /grant:r `"$($env:USERNAME):(R)`"" -Wait -NoNewWindow -PassThru
                if ($result.ExitCode -ne 0) {
                    throw "Falha no comando icacls"
                }
                
                Write-Host "$GREEN[Informação]$NC Permissões definidas com sucesso"
            }
            catch {
                Write-Host "$RED[Erro]$NC Falha ao definir permissões"
                Show-ManualGuide
                return
            }

            try {
                $fileInfo = Get-ItemProperty $updaterPath
                if (-not $fileInfo.IsReadOnly) {
                    Write-Host "$RED[Erro]$NC Verificação falhou: permissões podem não ter sido aplicadas"
                    Show-ManualGuide
                    return
                }
            }
            catch {
                Write-Host "$RED[Erro]$NC Falha na verificação"
                Show-ManualGuide
                return
            }

            Write-Host "$GREEN[Informação]$NC Atualização automática desativada com sucesso"
        }
        catch {
            Write-Host "$RED[Erro]$NC Erro desconhecido: $_"
            Show-ManualGuide
        }
    }
    else {
        Write-Host "$GREEN[Informação]$NC Mantendo configuração padrão, sem alterações"
    }

    Generate-NewConfig
    Update-MachineGuid
    Show-FileTree

} catch {
    Write-Host "$RED[Erro]$NC Falha na operação principal: $_"
    Write-Host "$YELLOW[Tentando]$NC Usando método alternativo..."
    
    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        $config | ConvertTo-Json | Set-Content -Path $tempFile -Encoding UTF8
        Copy-Item -Path $tempFile -Destination $STORAGE_FILE -Force
        Remove-Item -Path $tempFile
        Write-Host "$GREEN[Informação]$NC Configuração escrita com sucesso usando método alternativo"
    } catch {
        Write-Host "$RED[Erro]$NC Todas as tentativas falharam"
        Write-Host "Detalhes do erro: $_"
        Write-Host "Arquivo alvo: $STORAGE_FILE"
        Write-Host "Certifique-se de ter permissões suficientes para acessar o arquivo"
        Read-Host "Pressione Enter para sair"
        exit 1
    }
}

Write-Host ""
Read-Host "Pressione Enter para sair"
exit 0

function Write-ConfigFile {
    param($config, $filePath)
    
    try {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $jsonContent = $config | ConvertTo-Json -Depth 10
        $jsonContent = $jsonContent.Replace("`r`n", "`n")
        
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($filePath),
            $jsonContent,
            $utf8NoBom
        )
        
        Write-Host "$GREEN[Informação]$NC Arquivo de configuração escrito com sucesso (UTF8 sem BOM)"
    }
    catch {
        throw "Falha ao escrever arquivo de configuração: $_"
    }
}

function Compare-Version {
    param (
        [string]$version1,
        [string]$version2
    )
    
    try {
        $v1 = [version]($version1 -replace '[^\d\.].*$')
        $v2 = [version]($version2 -replace '[^\d\.].*$')
        return $v1.CompareTo($v2)
    }
    catch {
        Write-Host "$RED[Erro]$NC Falha na comparação de versões: $_"
        return 0
    }
}

Write-Host "$GREEN[Informação]$NC Verificando versão do Cursor..."
$cursorVersion = Get-CursorVersion

if ($cursorVersion) {
    $compareResult = Compare-Version $cursorVersion "0.45.0"
    if ($compareResult -ge 0) {
        Write-Host "$RED[Erro]$NC Versão atual ($cursorVersion) não suportada"
        Write-Host "$YELLOW[Sugestão]$NC Use a versão v0.44.11 ou inferior"
        Write-Host "$YELLOW[Sugestão]$NC Baixe a versão suportada em:"
        Write-Host "Windows: https://download.todesktop.com/230313mzl4w4u92/Cursor%20Setup%200.44.11%20-%20Build%20250103fqxdt5u9z-x64.exe"
        Write-Host "Mac ARM64: https://dl.todesktop.com/230313mzl4w4u92/versions/0.44.11/mac/zip/arm64"
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    else {
        Write-Host "$GREEN[Informação]$NC Versão atual ($cursorVersion) suporta redefinição"
    }
}
else {
    Write-Host "$YELLOW[Aviso]$NC Não foi possível detectar a versão, continuando..."
} 