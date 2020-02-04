resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

name 'ESX_CustomJobs'
author 'TigoDevelopment'
contact 'me@tigodev.com'
version '0.0.1'

description 'This is a repsitory where you can create your own jobs and it is easier to expand it. Here jobs have a possibility for an F6 menu.'

server_scripts {
    '@es_extended/locale.lua',

    'locales/en.lua',
    'locales/nl.lua',

    'config.lua',

    'server/common.lua',

    'shared/functions.lua',

    'server/main.lua'
}

client_scripts {
    '@es_extended/locale.lua',

    'locales/en.lua',
    'locales/nl.lua',

    'client/main.lua'
}