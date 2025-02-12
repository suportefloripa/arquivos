function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random() * 16 | 0;
        const v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

function showOSInstructions(os) {
    // Atualiza os botões
    document.querySelectorAll('.os-btn').forEach(btn => {
        btn.classList.remove('active');
        btn.classList.add('bg-gray-300');
        btn.classList.remove('bg-blue-500');
    });
    
    // Ativa o botão selecionado
    const selectedBtn = document.querySelector(`[onclick="showOSInstructions('${os}')"]`);
    selectedBtn.classList.add('active');
    
    // Esconde todas as instruções
    document.querySelectorAll('.os-instructions').forEach(inst => {
        inst.classList.add('hidden');
    });
    
    // Mostra as instruções do SO selecionado
    document.getElementById(`${os}-instructions`).classList.remove('hidden');
    
    // Atualiza o código de configuração para o SO selecionado
    const key = document.getElementById('generatedKey').value;
    if (key) {
        const configTemplate = {
            "telemetry.machineId": key,
            "telemetry.macMachineId": key,
            "telemetry.devDeviceId": key,
            "telemetry.sqmId": key,
            "lastModified": new Date().toISOString(),
            "version": "1.0.1"
        };
        
        document.getElementById(`configCode${os === 'windows' ? '' : '-' + os}`).textContent = 
            JSON.stringify(configTemplate, null, 2);
    }
}

// Função para gerar a chave quando o botão é clicado
document.getElementById('generateBtn').addEventListener('click', function() {
    const key = generateUUID();
    document.getElementById('generatedKey').value = key;
    
    const configTemplate = {
        "telemetry.machineId": key,
        "telemetry.macMachineId": key,
        "telemetry.devDeviceId": key,
        "telemetry.sqmId": key,
        "lastModified": new Date().toISOString(),
        "version": "1.0.1"
    };
    
    // Atualiza todos os blocos de código
    ['', '-mac', '-linux'].forEach(suffix => {
        const element = document.getElementById(`configCode${suffix}`);
        if (element) {
            element.textContent = JSON.stringify(configTemplate, null, 2);
        }
    });
    
    document.getElementById('resultSection').classList.remove('hidden');
});

// Função para copiar a chave para a área de transferência
function copyToClipboard() {
    const keyInput = document.getElementById('generatedKey');
    keyInput.select();
    document.execCommand('copy');
    
    const copyBtn = keyInput.nextElementSibling;
    const originalText = copyBtn.textContent;
    copyBtn.textContent = 'Copiado!';
    setTimeout(() => copyBtn.textContent = originalText, 1500);
}

// Adicionar esta nova função
function copyConfig(elementId) {
    const element = document.getElementById(elementId);
    const text = element.textContent;
    
    navigator.clipboard.writeText(text).then(() => {
        const copyBtn = element.nextElementSibling;
        const originalText = copyBtn.textContent;
        copyBtn.textContent = 'Copiado!';
        setTimeout(() => copyBtn.textContent = originalText, 1500);
    });
}

// Adicionar esta nova função
function copySettings() {
    const settings = {
        "update.mode": "none",
        "update.showReleaseNotes": false,
        "update.enableWindowsBackgroundUpdates": false
    };
    
    navigator.clipboard.writeText(JSON.stringify(settings, null, 4)).then(() => {
        const copyBtn = document.querySelector('[onclick="copySettings()"]');
        const originalText = copyBtn.textContent;
        copyBtn.textContent = 'Copiado!';
        setTimeout(() => copyBtn.textContent = originalText, 1500);
    });
}

// Adicionar esta nova função
function copyMacSettings() {
    const settings = {
        "security.workspace.trust.enabled": false,
        "security.workspace.trust.startupPrompt": "never",
        "security.workspace.trust.banner": "never",
        "security.workspace.trust.emptyWindow": false,
        "telemetry.telemetryLevel": "off"
    };
    
    navigator.clipboard.writeText(JSON.stringify(settings, null, 4)).then(() => {
        const copyBtn = document.querySelector('[onclick="copyMacSettings()"]');
        const originalText = copyBtn.textContent;
        copyBtn.textContent = 'Copiado!';
        setTimeout(() => copyBtn.textContent = originalText, 1500);
    });
}

// Adicionar esta nova função
function copyPowerShellCmd() {
    const command = 'irm cursor_win_id_modifier_pt-br.ps1 | iex';
    
    navigator.clipboard.writeText(command).then(() => {
        const copyBtn = document.querySelector('[onclick="copyPowerShellCmd()"]');
        const originalText = copyBtn.textContent;
        copyBtn.textContent = 'Copiado!';
        setTimeout(() => copyBtn.textContent = originalText, 1500);
    });
} 