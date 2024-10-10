# Pop!_OS Config Via Ansible

Inspirado por um vídeo do Learn Linux TV, este repositório documenta minha jornada com Ansible para configurar o Pop!_OS. Como novo usuário Linux, estou usando este projeto para aprender novas habilidades e personalizar meu sistema.

## Ansible Pull Command
```bash
sudo ansible-pull -U https://github.com/thomasgroch/ansible_popos.git
```

## GNOME Settings Trick

Here's a great way to figure out what tasks to setup in your GNOME settings
```bash
dconf dump / > before.txt
```
```bash
dconf dump / > after.txt
```
```bash
diff before.txt after.txt
```

<!-- [tg@tgworkstation ansible_popos]$ sudo -u ansible bash -->
<!-- ansible@tgworkstation:/home/tg $ echo "$(pass show vault_key)" > /home/ansible/.vault_key -->


## Todo

- [ ] Setup Windows VM task
- [ ] Default Package List
