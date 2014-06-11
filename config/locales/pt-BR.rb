# encoding: utf-8
{
  :'pt-BR' => {
    :application => {
      :require_ssh_keys_error => "Você precisa fazer upload da sua chave pública primeiro",
      :require_current_user => "Malvado %{title}, malvado! Você não deveria estar revirando as coisas de outras pessoas!",
      :no_commits_notice => "O repositório não tem nenhum commit ainda",
    },
    :admin => {
      :users_controller => {
        :create_notice => 'O usuário foi criado com sucesso.',
        :suspend_notice => "O usuário %{user_name} foi suspenso com sucesso.",
        :suspend_error => "Não consguiu suspender usuário %{user_name}.",
        :unsuspend_notice => "O usuário %{user_name} foi suspenso com sucesso.",
        :unsuspend_error => "Não conseguiu reativar usuário %{user_name}."
      },
      :check_admin => "Apenas Para Administradores"
    },
    :mailer => {
      :repository_clone => "%{login} clonou %{slug}/%{parent}",
      :request_notification => "%{login} requisitou um merge em %{title}",
      :code_comment => "%{login} comentou sua requisição de merge",
      :new_password => "Sua nova senha",
      :subject  => 'Por favor ative sua nova conta',
      :activated => 'Sua conta foi ativada!',
    },
    :blobs_controller => {
      :raw_error => "Blob é muito grande. Clone o repositório localmente para visualizá-lo",
    },
    :comments_controller => {
      :create_success => "Seu comentário foi adicionado",
    },
    :committers_controller => {
      :create_error_not_found => "Não foi possível encontrar usuário com esse nome",
      :create_error_already_commiter => "Não foi possível adicionar usuário ou usuário já é um committer",
      :destroy_success => "Usuário removido do repositório",
      :destroy_error => "Não foi possível remover usuário do repositório",
      :find_repository_error => "Você não é o criador deste repositório",
    },
    :keys_controller => {
      :create_notice => "Chave adicionada",
      :destroy_notice => "Chave removida"
    },
    :merge_requests_controller => {
      :create_success => "Você enviou uma requisição de merge para \"%{name}\"",
      :resolve_notice => "A requisição de merge foi marcada como %{status}",
      :resolve_disallowed => "A requisição de merge não pode ser marcada como %{status}",
      :update_success => "A Requisição de Merge foi atualizada",
      :destroy_success => "A Requisição de Merge foi retratada",
      :assert_resolvable_error => "Você não tem permissão para resolver esta Requisição de Merge",
      :assert_ownership_error => "Você não é o criador desta Requisição de Merge",
      :need_contribution_agreement => "Você precisa aceitar o acordo de contribuição",
      :reopened => 'A requisição para merge foi reaberta',
      :reopening_failed => 'A requisição para merge não pode ser reaberta'
    },
    :projects_controller => {
      :update_error => "Você não é o criador deste projeto",
      :destroy_error => "Você não é o criador deste projeto, ou o projeto tem clones",
      :create_only_for_site_admins => "Apenas administradores do site podem criar novos projetos",
    },
    :repositories_controller => {
      :new_clone_error => "Desculpe, não se pode clonar um repositório vazio",
      :create_clone_error => "Desculpe, não se pode clonar um repositório vazio",
      :create_success => "Novo repositório criado",
      :destroy_notice => "O repositório foi apagado",
      :destroy_error => "Você não é o criador deste repositório",
      :adminship_error => "Desculpe, somente administradores do projeto têm permissão para fazer isso",
      :only_projects_create_new_error => "Você só pode adicionar repositórios diretamente para um projeto",
    },
    :trees_controller => {
      :archive_error => "O repositório fornecido ou o SHA é inválido"
    },
    :groups_controller => {
      :group_created => "Equipe criada",
    },
    :users_controller => {
      :activate_notice => "Sua conta foi ativada, bem vindo!",
      :activate_error => "Código de ativação inválido",
      :reset_password_notice => "Uma nova senha foi enviada para seu e-mail",
      :reset_password_error => "E-mail inválido",
      :reset_password_inactive_account  => 'Sua conta não foi ativada ainda. Por favor, verifique sua caixa postal (incluindo sua pasta de spam) por uma mensagem de ativação do Gitorious',
    },
    :pages_controller => {
      :invalid_page_error => "página inválida, título ou corpo com má formatação",
      :no_changes => "Nenhuma mudança foi enviada",
      :repository_not_ready => "O Wiki está sendo criado",
    },
    :memberships_controller => {
      :membership_created => "Associação criada com sucesso",
      :membership_updated => "Associação atualizada",
      :failed_to_destroy => "Esta associação não pode ser removido",
      :membership_destroyed => "Associação excluída",
    },
    :application_helper => {
      :notice_for => "Este(a) %{class_name} está sendo criado(a),<br /> ficará pronto(a) muito em breve&hellip;",
      :event_status_add_project_repository => "repositório criado",
      :event_status_created => "projeto criado",
      :event_status_deleted => "projeto apagado",
      :event_status_updated => "projeto atualizado",
      :event_added_favorite => "observação iniciada",
      :event_status_cloned => "clonado",
      :event_updated_repository => 'repositório atualizado',
      :event_status_deleted => "apagado",
      :event_status_pushed => "comitado",
      :event_status_started => "desenvolvimento iniciado",
      :event_branch_created => "branch criado",
      :event_branch_deleted => "branch apagado",
      :event_tagged => "tagueado",
      :event_tag_deleted => "tag apagado",
      :event_committer_added => "committer adicionado",
      :event_committer_removed => "committer removido",
      :event_commented => "comentado",
      :event_requested_merge_of => "requisitado merge de",
      :event_resolved_merge_request => "requisição de merge resolvido",
      :event_reopened_merge_request => 'requisição de merge reaberta',
      :event_updated_merge_request => "requisição de merge atualizado",
      :event_deleted_merge_request => "requisição de merge apagado",
      :event_status_push_wiki => "conteúdo de wiki gravado",
      :event_updated_wiki_page => "página de wiki editada",
      :event_status_pushed => 'Alguns commits foram pushed',
      :event_status_committed => 'committed',
      :event_pushed_n => "pushed %{commit_link}",
      :more_info => "Mais informação…",
    },
    :project => {
      :format_slug_validation => "deve bater com alguma coisa no intervalo de [a-z0-9_\-]+",
      :http_required => "Deve iniciar com http(s)",
    },
    :user => {
      :invalid_url => "URL inválida",
    },
    :membership => {
      :notification_subject => "Você foi adicionado a uma equipe",
      :notification_body => "%{inviter} adicionou você para a equipe \"%{group}\", como um %{role}",
    },
    :committership => {
      :notification_subject => "Um novo commiter foi adicionado",
      :notification_body => "%{inviter} adicionou %{user} como um committer para %{repository} no projeto %{project}",
    },
    :ssh_key => {
      :key_format_validation_message => "não parece ser uma chave pública válida",
    },
    :views => {
      :layout => {
        :system_notice => "Notificação de Sistema",
        :home => "Início",
        :dashboard => "Dashboard",
        :admin => "Administração",
        :projects => "Projetos",
        :search => "Pesquisa",
        :faq => "Q&A",
        :about => "Sobre",
        :my_account => "Minha conta",
        :logout => "Sair",
        :login => "Acessar",
        :register => 'Registrar',
        :project_overview => "Resumo do Projeto",
        :repositories => "Repositórios",
        :pages => "Páginas Wiki",
        :user_mgt => "Gerenciamento de Usuários",
        :discussion => "Grupo de Discussão",
        :teams => 'Equipes',
        :blog => 'Blog',
      },
      :site => {
        :login_box_header => "Já é registrado?",
        :page_title => "Hospedagem Gratuita de Projetos Open Source",
        :description => "<strong>Gitorious</strong> quer fornecer uma grande\nmaneira de colaborar com código opensource de forma distribuída",
        :for_projects => "Para Projetos",
        :for_contributors => "Para Colaboradores",
        :newest_projects => "Projetos mais Recentes",
        :view_more => "Ver mais &raquo;",
        :dashboard => {
          :page_title => "Dashboard do %{login}",
          :activities => "Atividades",
          :your_projects => "Seus projetos:",
          :your_clones => "Seus clones de repositórios",
          :your_account => "Sua Conta",
          :your_profile => "Seu Perfil",
          :projects => "Projetos",
          :repositories => "Repositórios",
          :team_memberships => "Associações de membros da equipe",
          :registration_button => "Registre agora"
        },
      },
      :events => {
        :page_title => "Eventos",
        :activities => "Atividades no Gitorious",
        :system_activities => "Atividades de Sistema",
      },
      :license => {
        :show_title => 'Acordo de Licença para o Usuário Final',
        :terms_accepted => 'Você aceitou os Termos de Uso',
        :terms_not_accepted => 'Você precisa aceitar os Termos de Uso',
        :terms_already_accepted => 'Você já aceitou os últimos termos de uso'
      },
      :keys => {
        :edit_title => "Editar uma chave SSH",
        :ssh_keys => "Suas Chaves de SSH",
        :manage_ssh_keys => 'Gerenciar chaves SSH',
        :add_ssh_key => "Adicionar Chave de SSH",
        :add_title => "Adicionar uma nova chave pública SSH",
        :your_public_key => "Sua chave pública",
        :hint => "Está normalmente localizada em ~/.ssh/id_rsa.pub ou ~/.ssh/id_dsa.pub.<br />Se quiser usar múltiplas chaves, terá que adicionar cada uma separadamente",
      },
      :users => {
        :activated => "Ativado?",
        :suspended => "Suspenso?",
        :reset_pwd => "Reiniciar Senha",
        :admin => "Admin?",
        :suspend => "Suspender",
        :unsuspend => "Dessuspender",
        :create_btn => "Criar Novo Usuário",
        :is_admin => "É Administrador?",
        :forgot_title => "Esqueceu sua senha?",
        :send_new_passwd => 'Envie-me uma nova senha',
        :openid_build_title => 'Conclua seu registro',
        :openid_build_description => 'Você precisa entrar com os seguintes detalhes:',
        :openid_failed => 'A autenticação por OpenID falhou.',
        :openid_canceled => 'A autenticação por OpenID foi cancelada.',
        :create_title => "Crie um novo usuário ou <a href=\"%{path}\">faça login diretamente com seu OpenID</a>",
        :create_description => "Criar uma nova conta de usuário lhe permite criar seus próprios projetos ou participar no desenvolvimento de qualquer um.",
        :wants_email_notifications => 'Enviar notificações por e-mail?',
        :describe_email_notifications => "Nós lhe enviaremos uma notificação por e-mail quando você receber uma mensagem no Gitorious",
        :default_favorite_notifications => "Por padrão, notificar-me de atualizações sobre o que eu estiver observando",
        :member_for => "Membro por",
        :this_week => {
          :one => "commit até agora esta semana",
          :other => "commits até agora esta semana",
        },
        :about => "cerca de %{about}",
        :edit_title => "Altere seus detalhes",
        :edit_action => 'Alterar detalhes',
        :realname => "Nome Real",
        :email => "E-mail",
        :url => "url de <small>blog etc</small>",
        :openid => "OpenID",
        :my_account => "Minha conta",
        :chg_passwd_action => "Alterar senha",
        :chg_passwd_title => "Altere sua senha",
        :new_passwd => "Nova senha",
        :new_passwd_conf => "Confirmação da nova senha",
        :edit_details => "Editar detalhes",
        :show_title => "Conta",
        :details_title => "Detalhes da Conta",
        :edit_link => "editar",
        :username => "Usuário",
        :create => "criar uma conta",
        :license => 'Acordo de Licença para o Usuário Final',
        :send_user_msg => "Enviar mensagem",
        :avatar => 'Imagem do perfil',
        :pending_activation => {
          :header => "Quase pronto",
          :info => "Um <strong>e-mail de confirmação</strong> será enviado para o endereço que você especificou. Este e-mail contém um link de ativação. Visite este link para finalizar o registro.",
          :thanks => "Estamos anciosos em vê-lo utilizando o Gitorious!"
        },
        :favorites_action => "Seus favoritos"
      },
      :logs => {
        :title => "Commits em %{repo_url}:%{ref}",
        :project => "Projeto",
        :maintainer => "Mantenedor",
        :head_tree => "árvore HEAD",
        :branches => "Branches",
        :tags => "Tags",
        :committed => "comitado",
      },
      :blobs => {
        :page_title => "%{path} - %{repo} em %{title}",
        :wrap => "Modo Softwrap",
        :title => "Blob de <code>%{path}</code>",
        :raw => "dado blob puro",
        :show => "Conteúdos Blob",
        :history => "Histórico Blob",
        :blame => "Culpados",
        :heading => "Histórico para %{ref}:%{path}",
        :too_big => "Este arquivo é muito grande para ser renderizado num tempo razoável, <a href=\"%{path}\">tente ver os dados puros</a>",
        :message => "Este conteúdo parece estar em formato binário. Se quiser, você pode <a href=\"%{path}\">baixar os dados puros</a> (clique com o botão direito, salvar como).",
      },
      :comments => {
        :commit => "no commit %{sha1}",
        :permalink => '<abbr title="permalink para este comentário">#</abbr>',
        :add_title => "Adicionar um novo comentário",
        :edit_title => "Mudar seu comentário",
        :body => "Comentário",
        :add => "Adicionar Comentário",
        :update_or_add => "Atualizar / Adicionar Comentário",
        :page_title => "Comentários em %{repo}",
        :diff => "Diferença de Commits",
        :total => "Comentários (%{total})",
        :page_title_2 => "Comentários no %{title}",
        :page_title_3 => "Comentários para repositório &quot;%{repo}&quot; em %{title}",
      },
      :commits => {
        :date => "Data",
        :committer => "Committer",
        :author => "Autor",
        :sha1 => "SHA1 do Commit",
        :tree_sha1 => "SHA1 da Árvore",
        :parent_sha1 => "SHA1 do Pai",
        :page_title => "Commit em %{repo} no %{title}",
        :title => "Commit %{commit}",
        :message => "Este é o commit inicial deste repositório, <a href=\"%{path}\">navegue pelo estado inicial da árvore</a>.",
      },
      :sessions => {
        :login => "Login",
        :label => "E-mail",
        :passwd => "Senha",
        :openid => "OpenID",
        :remember => "Lembre-se de mim",
        :submit => 'Entrar',
        :register => "Registrar",
        :forgot => "Esqueceu sua senha?",
        :openid_url => "URL OpenID",
        :email => "E-mail",
        :to_openid => "Mudar para OpenID",
        :to_regular => "Mudar para login normal",
        :regular_login_header => "Login normal",
        :openid_login_header => "Login por OpenID"
      },
      :searches => {
        :search => "Pesquisa",
        :hint => %Q{ex. 'wrapper', 'category:python' ou '"document database"'},
        :page_title => %Q{Pesquisa por "%{term}"},
        :no_results => "Desculpe, nada encontrado para %{term}",
        :found => {
          :one => "Encontrado %{count} resultado em %{time}ms",
          :other => "Encontrado %{count} resultados em %{time}ms",
        },
      },
      :trees => {
        :page_title => "Árvore para %{repo} em %{title}",
        :title => "Árvore do repositório %{repo} em %{title}",
        :download => "Faça download como um arquivo compactado (tar.gz)",
        :branch => "Ramo",
      },
      :repos => {
        :overview => "Resumo",
        :commits => "Commits",
        :tree => "Árvore de Código",
        :comments => "Comentários (%{count})",
        :requests => "Requisições de Merge (%{count})",
        :public_url => "URL Pública de clone",
        :your_clone_url => "Sua url para push",
        :clone_this_repo => "Clone este repositório",
        :more_info => "Mais informações…",
        :help_clone => "Você pode clonar este repositório com o seguinte comando",
        :help_clone_http => "note que clonar sobre HTTP é mais lento, mas útil se estiver atrás de um firewall",
        :http_url => "URL para clone via HTTP",
        :push_url => "URL Privada de Push",
        :owner => "criador",
        :creator => "criador",
        :project => "Projeto",
        :confirm_delete => "Por favor, confirme apagar o %{repo} em %{title}",
        :message_delete => "Quando o botão for apertado, o repositório será apagado",
        :btn_delete => "SIM, tenho certeza que quero apagar este repositório permanentemente",
        :page_title => "Repositórios em %{repo}",
        :title => "Repositórios",
        :commits => "Commits",
        :tree => "Árvore",
        :activities => { :one => "atividade", :other => "atividades" },
        :branches => { :one => "branch", :other => "branches" },
        :authors => { :one => "autor", :other => "autores" },
        :name => %Q{Nome <small>(ex "%{name}-sandbox", "conserto-performance" etc.)</small>},
        :btn_clone => "Clonar Repositório",
        :back => "Retornar ao Repositório",
        :show_page_title => "%{repo} em %{title}",
        :show_title => "repositório &quot;%{repo}&quot; em %{title}",
        :committers_title => "Adicionar committers para %{repo} em %{title}",
        :committers_manage_group_members => "Gerenciar membros da equipe para %{group}",
        :committers_howto => "Há duas formas de adicionar commiters para um repositório: adicionando membros para a equipe que é dona do repositório, ou adicionando outra equipe como committers.",
        :transfer_owner => "Transferir posse",
        :current_owner_project => "O repositório pertence atulamente ao projeto %{project_name} (o qual pertence a você).",
        :current_owner_user => "O repositório pertence atualmente a você.",
        :transfer_owner_howto => "Se você desejar, você pode transferir a posse deste repositório para uma equipe
                                  na qual você seja administrador. Desta forma você pode adicionar múltiplos usuários
                                  como commiters, sem requerir que eles iniciem uma nova equipe.",
        :add_committer_group => "Ou você pode adicionar uma equipe existente como commiters para o repositório,
                                 dando acesso de commit a todos os membros.",
        :activities => "Atividades",
        :clone_of => "Clone de",
        :created => "Criado",
        :btn_request => "Requisitar Merge",
        :btn_add_committer => "Adicionar Committer",
        :btn_add_committers => "Adicionar Commiters",
        :btn_manage_collaborators => "Gerenciar colaboradores",
        :btn_delete_repo => "Apagar Repositório",
        :btn_edit_repo => "Editar repositório",
        :committers => "Committers",
        :current_committers => "Committers",
        :remove => "Remover",
        :create_title => "Criar um clone de <a href=\"%{clone_url}\">%{clone_name}</a> <small>em <a href=\"%{project_url}\">%{project_name}</a></small>",
        :edit_group => "Editar/exibir membros da equipe",
        :show_group => "Exibir membros da equipe",
        :by_teams => "Clones da equipe",
        :by_users => "Clones pessoais",
        :merge_requests_enabled => "Requisições de merge permitem aos usuários do Gitorious a lhe requisitarem para mesclar as contribuições que eles fazem ao seu código."
      },
      :projects => {
        :title => "Projetos",
        :back => "Voltar à tela de edição",
        :hint => %Q{São permitidos <a href="http://daringfireball.net/projects/markdown/">Markdown</a> e HTML básico},
        :categories => "Categorias",
        :delete => "Apagar projeto",
        :delete_title => "Por favor, confirme apagar o %{title}",
        :delete_message => "Uma vez que o botão for pressionado o projeto será apagado",
        :delete_btn => "SIM, tenho certeza que quero apagar este projeto permanentemente",
        :edit => "Editar projeto",
        :update_title => "Atualizar %{link}",
        :new => "Novo projeto",
        :create_new => "Criar um novo projeto",
        :popular => "Categorias Populares",
        :new_title => "Criar um novo projeto",
        :new_hint => %Q(Um repositório "mainline" padrão será criado junto com o projeto, permitindo que você comece a fazer commits imediatamente.),
        :create => "Criar projeto",
        :labels => "Etiquetas",
        :license => "Licença",
        :owner => "Criador",
        :created => "Criado",
        :website => "Site em ",
        :mailing => "Lista de Discussão em ",
        :bugtracker => "Gerenciador de Bugs em ",
        :repos => "Repositórios",
        :manage_access => "Gerenciar Acesso",
        :repository_clones => "Clones do repositório",
        :no_clones_yet => "Não há clones deste repositório no Gitorious ainda",
        :project_members => "Membros do projeto",
        :add_repository => "Adicionar repositório",
        :edit_oauth_settings => 'Editar configurações de contribuição',
        :edit_slug_title => 'Editar o slug (para URLs etc.)',
        :edit_slug_disclaimer => 'Note que alterando o slug, <strong>todas as URLs, incluindo as URLs do git, serão alteradas</strong>',
        :update_slug => 'Atualizar slug',
        :merge_request_states_hint => 'Cada linha deveria conter um tag de status que pode ser selecionado para requisições de merge neste projeto'
      },
      :project_memberships => {
          :collaborator => "Colaborador",
          :back_to_project => "Voltar ao projeto",
          :is_public => "Projeto é público",
          :is_public_description => "Qualquer um com acesso a %{site_name} pode acessar este projeto e seus repositórios.",
          :make_private => "Tornar privado",
          :make_public => "Abrir este projeto para o público."
      },
      :repository_memberships => {
          :collaborator => "Membro",
          :back_to_repository => "Voltar ao repositório",
          :is_public => "Repositório é aberto",
          :is_public_description => "Qualquer um com acesso ao projeto %{project} pode navegar nesse repositório.",
          :make_private => "Tornar privado",
          :make_public => "Abrir acesso ao repositório. Se o projeto for também privado, isto irá abrir acesso apenas aos membros do projeto."
      },
      :merges => {
        :info => {
          :target_repos => "O repositório onde você acha que este deve ser mesclado com",
          :target_branch => "O branch de destino onde quer que suas mudanças sejam mescladas",
          :source_branch => "O branch de origem de onde o repositório de destino deve pegar as mudanças para mesclar",
          :summary => "Um resumo de uma linha das suas mudanças",
          :proposal => "Uma breve descrição de suas mudanças",
        },
        :summary_title => "%{source} requisitou um merge com %{target}",
        :review => "Revisar requisição de merge &#x2192;",
        :edit_title => "Editar requisição de merge",
        :page_title => "Requisições de merge em %{repo}",
        :hint => %Q{Uma "requisição de merge" é uma notificação de um repositório para outro de que gostaria que suas mudanças fossem mescladas para cima.},
        :no_merge => "Nenhuma requisição de merge ainda",
        :create_title => "Criar uma requisição de merge",
        :create_btn => "Criar requisição de merge",
        :show_title => "Revisando requisição de merge \#%{id}: %{summary}",
        :edit_btn => "Editar requisição de merge",
        :delete_btn => 'Excluir requisição de merge',
        :example => "Exibir fluxo de trabalho de exemplo",
        :commits_to_merged => "Commits que seriam mesclados",
        :commits => 'Commits',
        :reopen_btn => 'Reabrir requisições de merge',
        :update_btn => "Atualizar requisição de merge",
      },
      :committers => {
        :title => "Dá direitos de commit ao repositório %{repo} para o usuário",
        :login => "Usuários existentes <small>(pesquisa-enquanto-digita)</small>",
        :add => "Adicionar como committer",
      },
      :common => {
        :confirm => "Tem certeza?",
        :create => "Criar",
        :creating => "Criando",
        :editing => "Editando",
        :edit => "Editar",
        :save => "Gravar",
        :delete => "apagar",
        :add => "Adicionar",
        :yes => "Sim",
        :no => "Não",
        :back => "Retornar",
        :signup => "Registrar",
        :toggle => "Alternar",
        :none => "nenhum(a)",
        :update => "Atualizar",
        :cancel => "cancelar",
        :or => "ou",
        :remove => "remover",
      },
      :pages => {
        :page => "página",
        :last_edited_by => "Editado pela última vez por %{link_or_name}",
        :or_back_to_page => "ou retornar para %{page_link}",
        :history => "Histórico",
        :last_n_edits => "Últimas %{n} edições em %{title}",
        :index => "Índice de páginas",
        :wikiwords_syntax => "[[Wikilink]] criará um link para uma página com este nome.",
        :git => "Acesso Git"
      },
      :memberships => {
        :add_new_member => "Adicionar novo membro",
        :role => "Papel do membro",
        :header_title => "Membros em %{group_name}",
        :new_title => "Adicionar novo membro para %{group_memberships}",
      },
      :groups => {
        :create_team => "Criar uma nova equipe",
        :update_team => 'Atualizar uma equipe',
        :team_name => "Nome da equipe",
        :project_name => "Nome do projeto",
        :create_team_submit => "Criar equipe",
        :update_team_submit => 'Atualizar equipe',
        :teams => "Equipes",
        :member_singular => "membro",
        :member_plural => "membros",
        :repo_singular => "repositório",
        :repo_plural => "repositórios",
        :new_team_after_create_hint => "Você pode adicionar mais membros à equipe depois de criá-lo",
        :edit_memberships => "Editar participações dos membros",
        :edit_team  => 'Editar equipe',
        :description => 'Descrição da equipe',
        :avatar => 'Imagem/logo da equipe:',
      },
      :collaborators => {
        :add_new => "Adicionar colaboradores",
        :title => "Usuários &amp; times colaborando em %{repo_name}",
        :committer_name => "Committer",
        :group_name => "Nome da equipe ",
        :user_login => "Nome de usuário",
        :add_user => "Adicionar um usuário",
        :add_team => "Adicionar uma equipe",
        :new_title => "Adicionar um usuário ou uma equipe como colaboradores em %{repo_name}",
        :btn_add_as_collaborator => "Adicionar como colaborador",
        :return_to => "retornar para",
        :or_return_to => "ou retornar para",
        :add_team_note => "<strong>Note</strong> que adicionar uma equipe dará a todos os membros
            as permissões que você selecionar",
      },
      :aliases => {
        :aliases_title => "Pseudônimos de e-mail",
        :new_alias => "Novo pseudônimo de e-mail",
        :manage_aliases => 'Gerenciar e-mails'
      },
      :messages => {
        :collection_title => "Mensagens",
        :title_new  => "Compor uma mensagem",
        :subject  => "Assunto",
        :body => "Corpo da mensagem",
        :recipient => "Escolha um ou mais destinatários, separados com vírgula",
        :submit => "Enviar mensagem",
        :index_message => "Caixa de entrada",
        :reply => "Responder",
        :received_messages => "Caixa de entrada",
        :all_messages => 'Arquivo',
        :sent_messages => "Mensagens enviadas",
        :new => "Compor uma mensagem",
        :mark_as_read => "Marcar como lida"
      }
    },

    # formatos de data e hora
    :date => {
      :formats => {
        :long_ordinal => lambda { |date| "#{date.day} de %B de %Y" },
        :default => "%d/%m/%Y",
        :short => lambda { |date| "#{date.day} %b" },
        :long => lambda { |date| "#{date.day} de %B de %Y" },
        :only_day => "%e",
      },
      :day_names => %w(Domingo Segunda Terça Quarta Quinta Sexta Sábado),
      :abbr_day_names => %w(Dom Seg Ter Qua Qui Sex Sáb),
      :month_names => [nil] + %w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro),
      :abbr_month_names => [nil] + %w(Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez),
      :order => [:day, :month, :year],
    },
    :time => {
      :formats => {
        :long_ordinal => lambda { |time| "#{time.day} de %B de %Y %H:%M" },
        :default => lambda { |time| "%A, #{time.day} de %B de %Y, %H:%M hs" },
        :time => "%H:%M hs",
        :short => lambda { |time| "#{time.day}/%m, %H:%M hs" },
        :long => lambda { |time| "%A, #{time.day} de %B de %Y, %H:%M hs" },
        :only_second => "%S",
        :human => "%A às %d de %B %Y",
        :short_time => "%H:%M",
        :datetime => {
          :formats => {
            :default => "%Y-%m-%dT%H:%M:%S%Z",
          },
        },
      },
      :time_with_zone => {
        :formats => {
          :default => lambda { |time| "%Y-%m-%d %H:%M:%S #{time.formatted_offset(false, 'UTC')}" }
        },
      },
      :am => '',
      :pm => '',
    },

    # date helper distanci em palavras
    :datetime => {
      :distance_in_words => {
        :half_a_minute => 'meio minuto',
        :less_than_x_seconds => {
          :one => 'menos de 1 segundo',
          :other => 'menos de %{count} segundos'
        },
        :x_seconds => {
          :one => '1 segundo',
          :other => '%{count} segundos'
        },
        :less_than_x_minutes => {
          :one => 'menos de um minuto',
          :other => 'menos de %{count} minutos'
        },
        :x_minutes => {
          :one => '1 minuto',
          :other => '%{count} minutos'
        },
        :about_x_hours => {
          :one => 'aproximadamente 1 hora',
          :other => 'aproximadamente %{count} horas'
        },
        :x_days => {
          :one => '1 dia',
          :other => '%{count} dias'
        },
        :about_x_months => {
          :one => 'aproximadamente 1 mês',
          :other => 'aproximadamente %{count} meses'
        },
        :x_months => {
          :one => '1 mês',
          :other => '%{count} meses'
        },
        :about_x_years => {
          :one => 'aproximadamente 1 ano',
          :other => 'aproximadamente %{count} anos'
        },
        :over_x_years => {
          :one => 'mais de 1 ano',
          :other => 'mais de %{count} anos'
        }
      }
    },

    # numeros
    :number => {
      :format => {
        :precision => 3,
        :separator => ',',
        :delimiter => '.'
      },
      :currency => {
        :format => {
          :unit => 'R$',
          :precision => 2,
          :format => '%u %n'
        }
      }
    },

    # Active Record
    :activerecord => {
      :models => {
        :comment => "Comentário",
        :event => "Evento",
        :group => "Equipe",
        :membership => "Associação de membro",
        :merge_request => "Requisição de Merge",
        :project => "Projeto",
        :repository => "Repositório",
        :role => "Papel de usuário",
        :ssh_key => "Chave SSH",
        :tags => "Categoria",
        :user => "Usuário",
      },
      :attributes => {
        :user => {
          :login => "Nome de usuário",
          :email => "E-mail",
          :current_password => "Senha atual",
          :password => "Senha",
          :password_confirmation => "Confirmação de senha",
          :created_at => "Criado Em",
          :updated_at => "Atualizado Em",
          :activation_code => "Código de Ativação",
          :activated_at => "Ativado em",
          :fullname => "Nome completo",
          :url => "Url",
          :public_email => "Exibir e-mail publicamente?"
        },
        :merge_request => {
          :target_repository_id => "Repositório Alvo",
          :summary => "Resumo",
          :proposal => "Descrição",
          :source_branch => "Ramo Fonte",
          :target_branch => "Ramo Alvo",
        },
        :project => {
          :title => "Title",
          :description => "Description (obligatory)",
          :slug => "Slug (for urls etc)",
          :license => "License",
          :home_url => "Home URL (if any)",
          :mailinglist_url => "Mailinglist URL (if any)",
          :bugtracker_url => "Bugtracker URL (if any)",
          :wiki_enabled => "Should the wiki be enabled?",
          :tag_list => "Categories (space separated)",
          :merge_request_states => 'Merge request states',
        },
        :comment => {
          :body => "Corpo",
        },
        :repository => {
          :name => "Nome",
          :ready => "Pronto",
          :wiki_permissions => "Permissões Wiki",
        },
        :keys => {
          :key => "Chave",
          :ready => "Pronto",
        },
        :roles => {
          :name => "Papel de usuário"
        },
        :memberships => {
          :created_at => "Criado em"
        },
        :committerships => {
          :created_at => "Criado em",
          :committer => "committer",
          :committer_type => "Tipo de committer",
          :repository => "Repositório",
          :permissions => "Permissões",
          :creator => "Adicionado por",
        }
      },
      :errors => {
        :template => {
          :header => {
            :one => "%{model} não pode ser salvo: 1 erro",
            :other => "%{model} não pode ser salvo: %{count} erros."
          },
          :body => "Por favor, cheque os seguintes campos:"
        },
        :messages => {
          :inclusion => "não está incluso na lista",
          :exclusion => "não está disponível",
          :invalid => "não é válido",
          :confirmation => "não bate com a confirmação",
          :accepted => "precisa ser aceito",
          :empty => "não pode ser vazio",
          :blank => "não pode ser vazio",
          :too_long => "é muito longo (não mais do que %{count} caracteres)",
          :too_short => "é muito curto (não menos do que %{count} caracteres)",
          :wrong_length => "não é do tamanho correto (precisa ter %{count} caracteres)",
          :taken => "não está disponível",
          :not_a_number => "não é um número",
          :greater_than => "precisa ser maior do que %{count}",
          :greater_than_or_equal_to => "precisa ser maior ou igual a %{count}",
          :equal_to => "precisa ser igual a %{count}",
          :less_than => "precisa ser menor do que %{count}",
          :less_than_or_equal_to => "precisa ser menor ou igual a %{count}",
          :odd => "precisa ser ímpar",
          :even => "precisa ser par"
        }
      }
    },
    :support => {
      :array => {
        :words_connector => ', ',
        :last_word_connector =>  ' e ',
        :two_words_connector =>  ' e '
      }
    }
  }
}
