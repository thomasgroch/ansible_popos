# Pop!_OS Config Via Ansible

Este repositório contém playbooks Ansible para automatizar a configuração do Pop!_OS. Inspirado por um vídeo do Learn Linux TV, este projeto documenta minha jornada com Ansible e serve como uma ferramenta de aprendizado para automação de configuração de sistema Linux.

## 🚀 Início Rápido

Para aplicar esta configuração em seu sistema Pop!_OS, execute:

```bash
sudo ansible-pull -U https://github.com/thomasgroch/ansible_popos.git
```

## 🔧 Funcionalidades

- Configuração automatizada do sistema Pop!_OS
- Gerenciamento de pacotes e dependências
- Configurações do GNOME personalizadas
- Jobs cron para manutenção automática:
  - Provisionamento automático a cada 3 horas
  - Limpeza do diretório `.ansible` no boot
  - Logs de execução em `/var/tmp/ansible_provision.log`

## 💡 Dicas e Truques

### Configurações do GNOME

Para identificar mudanças nas configurações do GNOME, use o seguinte método:

1. Exporte as configurações atuais:
```bash
dconf dump / > before.txt
```

2. Faça as alterações desejadas na interface

3. Exporte novamente:
```bash
dconf dump / > after.txt
```

4. Compare as diferenças:
```bash
diff before.txt after.txt
```

## 📋 Todo

- [ ] Setup Windows VM task
- [ ] Default Package List
- [ ] Documentar todas as tasks disponíveis
- [ ] Adicionar instruções de contribuição
- [ ] Adicionar seção de troubleshooting

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues e pull requests.

## 📝 Licença

Este projeto está sob a licença MIT.
