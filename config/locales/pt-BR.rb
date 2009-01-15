{
  :'pt-BR' => {
    :application => {
      :require_ssh_keys_error => "Você precisa fazer upload da sua chave pública primeiro",
      :no_commits_notice => "O repositório não tem nenhum commit ainda",
    },
    :admin => {
      :users_controller => {
        :create_notice => 'O usuário foi criado com sucesso.',
        :suspend_notice => "O usuário {{user_name}} foi suspenso com sucesso.",
        :suspend_error => "Não consguiu suspender usuário {{user_name}}.",
        :unsuspend_notice => "O usuário {{user_name}} foi suspenso com sucesso.",
        :unsuspend_error => "Não conseguiu reativar usuário {{user_name}}.",
        :check_admin => "Apenas Para Administradores",
      },
    },
    :mailer => {
      :repository_clone => "{{login}} clonou {{slug}}/{{parent}}",
      :request_notification => "{{login}} requisitou um merge em {{title}}",
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
      :create_success => "Você enviou uma requisição de merge para \"{{name}}\"",
      :resolve_notice => "A requisição de merge foi marcada como {{status}}",
      :update_success => "A Requisição de Merge foi atualizada",
      :destroy_success => "A Requisição de Merge foi retratada",
      :assert_resolvable_error => "Você não tem permissão para resolver esta Requisição de Merge",
      :assert_ownership_error => "Você não é o criador desta Requisição de Merge"
    },
    :projects_controller => {
      :update_error => "Você não é o criador deste projeto",
      :destroy_error => "Você não é o criador deste projeto, ou o projeto tem clones",
    },
    :repositories_controller => {
      :new_error => "Desculpe, não se pode clonar um repositório vazio",
      :create_error => "Desculpe, não se pode clonar um repositório vazio",
      :destroy_notice => "O repositório foi apagado",
      :destroy_error => "Você não é o criador deste repositório",
      :adminship_error => "Desculpe, somente administradores do projeto têm permissão para fazer isso",
    },
    :trees_controller => {
      :archive_error => "O repositório fornecido ou o SHA é inválido"
    },
    :users_controller => {
      :create_notice => "Obrigado por se registrar! Você receberá um e-mail para ativação em breve",
      :activate_notice => "Sua conta foi ativada, bem vindo!",
      :activate_error => "Código de Ativação inválida",
      :reset_password_notice => "Uma nova senha foi enviada para seu e-mail",
      :reset_password_error => "E-mail inválido",
    },
    :application_helper => {
      :notice_for => lambda { |class_name| "Este(a) #{class_name} está sendo criado(a),<br /> ficará pronto(a) muito em breve&hellip;"},
      :event_status_created => "projeto criado",
      :event_status_deleted => "projeto apagado",
      :event_status_updated => "projeto atualizado",
      :event_status_cloned => "clonado",
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
      :event_updated_merge_request => "requisição de merge atualizado",
      :event_deleted_merge_request => "requisição de merge apagado",
    },
    :project => {
      :format_slug_validation => "deve bater com alguma coisa no intervalo de [a-z0-9_\-]+",
      :ssl_required => "Deve iniciar com http(s)",
    },
    :user => {
      :invalid_url => "URL inválida",
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
        :project_overview => "Resumo do Projeto",
        :repositories => "Repositórios",
        :user_mgt => "Gerenciamento de Usuários",
        :discussion => "Grupo de Discussão",
      },
      :site => {
        :page_title => "Hospedagem Gratuita de Projetos Open Source",
        :description => "<strong>Gitorious</strong> quer fornecer uma grande\nmaneira de colaborar com código opensource de forma distribuída",
        :for_projects => "Para Projetos",
        :for_contributors => "Para Colaboradores",
        :creating_account => lambda { |this, path| 
          this.link_to("Criar uma conta de usuário", path) + 
          " lhe permite criar seus próprios projetos ou participar do desenvolvimento de qualquer outro." },
        :newest_projects => "Projetos mais Recentes",
        :view_more => "Ver mais &raquo;",
        :dashboard => {
          :page_title => "Dashboard do {{login}}",
          :activities => "Atividades",
          :your_projects => "Seus projetos:",
          :your_clones => "Seus clones de repositórios",
          :your_account => "Sua Conta",
          :your_profile => "Seu Perfil",
          :projects => "Projetos",
          :clones => "Clones de repositórios",
        },
      },
      :events => {
        :page_title => "Eventos",
        :activities => "Atividades no Gitorious",
        :system_activities => "Atividades de Sistema",
      },
      :account => {
        :edit_title => "Edite sua conta",
        :realname => "Nome Real",
        :url => "url de <small>blog etc</small>",
        :openid => "OpenID",
        :my_account => "Minha conta",
        :chg_passwd => "Mudar senha",
        :new_passwd => "Nova senha",
        :new_passwd_conf => "Confirmação da nova senha",
        :edit_details => "Editar detalhes",
        :show_title => "Conta",
        :details_title => "Detalhes da Conta",
        :edit_link => "editar",
        :username => "Usuário",
        :create => "criar uma conta",
      },
      :keys => {
        :edit_title => "Editar uma chave SSH",
        :ssh_keys => "Suas Chaves de SSH",
        :add_ssh_key => "Adicionar Chave de SSH",
        :add_title => "Adicionar uma nova chave pública SSH",
        :your_public_key => "Sua chave pública",
        :hint => "Está normalmente localizada em ~/.ssh/id_rsa.pub ou ~/.ssh/id_dsa.pub.<br />Se quiser usar múltiplas chaves, terá que adicionar cada uma separadamente",
      },
      :users => {
        :activated => "Ativado?",
        :suspended => "Suspenso?",
        :admin => "Admin?",
        :suspend => "Suspender",
        :unsuspend => "Dessuspender",
        :create_btn => "Criar Novo Usuário",
        :is_admin => "É Administrador?",
        :forgot_title => "Esqueceu sua senha?",
        :send_new_passwd => 'Me envie uma nova senha',
        :create_title => lambda { |this, path| "Crie um novo usuário ou " + 
          this.link_to( "faça login diretamente com seu OpenID", path ) },
        :create_description => "Criar uma nova conta de usuário lhe permite criar seus próprios projetos ou participar no desenvolvimento de qualquer um.",
        :member_for => "Membro por",
        :this_week => {
          :one => "commit até agora esta semana",
          :other => "commits até agora esta semana", 
        },
        :about => "cerca de {{about}}",
      },
      :logs => {
        :page_title => "Commits em {{repo}} em {{title}}",
        :commitlog => "Log de Commit para {{repo}}:{{param}} em {{title}}",
        :project => "Projeto",
        :maintainer => "Mantenedor",
        :head_tree => "árvore HEAD",
        :branches => "Branches",
        :tags => "Tags",
      },
      :blobs => {
        :page_title => "{{path}} - {{repo}} em {{title}}",
        :wrap => "Modo Softwrap",
        :title => "Blob de <code>{{path}}</code>",
        :raw => "dado blob puro",
        :too_big => lambda { |this, path| "Este arquivo é muito grande para ser renderizado num tempo razoável, " +
          this.link_to("tente ver os dados puros", path) },
        :message => lambda { |this, mime, path| "Não há certeza que esse blob pode ser mostrado corretamente (é um mimetype \"#{mime}\"), " +
          this.link_to("tente ver os dados puros", path) + 
          "e veja se se browser consegue carregar isso." },
      },
      :comments => {
        :commit => "no commit {{sha1}}",
        :permalink => '<abbr title="permalink para este comentário">#</abbr>',
        :add_title => "Adicionar um novo comentário",
        :body => "Comentário",
        :add => "Adicionar Comentário",
        :page_title => "Comentários em {{repo}}",
        :diff => "Diferença de Commits",
        :total => "Comentários ({{total}})",
        :page_title_2 => "Comentários no {{title}}",
        :page_title_3 => "Comentários para repositório &quot;{{repo}}&quot; em {{title}}",
      },
      :commits => {
        :date => "Data",
        :committer => "Committer",
        :author => "Autor",
        :sha1 => "SHA1 do Commit",
        :tree_sha1 => "SHA1 da Árvore",
        :page_title => "Commit em {{repo}} no {{title}}",
        :title => "Commit {{commit}}",
        :message => lambda { |this, path| "Este é o commit inicial deste repositório, " +
          this.link_to( "navegue pelo estado inicial da árvore", path ) + "." },
      },
      :sessions => {
        :login => "Login",
        :label => lambda { |this| "E-mail ou #{this.switch_login('alterne para OpenID','to_openid')}" },
        :passwd => "Senha",
        :openid => lambda { |this| "OpenID ou #{this.switch_login('alterne para login por e-mail', 'to_email')}"},
        :remember => "Lembre-se de mim",
        :submit => 'Entrar',
        :register => "Registrar",
        :forgot => "Esqueceu sua senha?",
      },
      :searches => {
        :search => "Pesquisa",
        :hint => %Q{ex. 'wrapper', 'category:python' ou '"document database"'},
        :page_title => %Q{Pesquisa por "{{term}}"},
        :no_results => "Desculpe, nada encontrado para {{term}}",
        :found => {
          :one => "Encontrado {{count}} resultado em {{time}}ms",
          :other => "Encontrado {{count}} resultados em {{time}}ms",
        },
      },
      :trees => {
        :page_title => "Árvore para {{repo}} em {{title}}",
        :title => "Árvore do repositório {{repo}} em {{title}}",
        :download => "Faça download como um arquivo compactado (tar.gz)",
      },
      :repos => {
        :overview => "Resumo",
        :commits => "Commits",
        :tree => "Árvore de Código",
        :comments => "Comentários ({{count}})",
        :requests => "Requisições de Merge ({{count}})",
        :public_url => "URL Pública de clone",
        :more_info => "Mais informações…",
        :help_clone => "Você pode clonar este repositório com o seguinte comando",
        :help_clone_http => "note que clonar sobre HTTP é mais lento, mas útil se estiver atrás de um firewall",
        :http_url => "URL para clone via HTTP",
        :push_url => "URL Privada de Push",
        :help_push => lambda { |repo| "Você pode executar \"<code>git push #{repo}</code>\", ou também pode configurar um repositório remoto da seguinte maneira:" },
        :owner => "criador",
        :confirm_delete => "Por favor, confirme apagar o {{repo}} em {{title}}",
        :message_delete => "Quando o botão for apertado, o repositório será apagado",
        :btn_delete => "SIM, tenho certeza que quero apagar este repositório permanentemente",
        :page_title => "Repositórios em {{repo}}",
        :title => "Repositórios",
        :commits => "Commits",
        :tree => "Árvore",
        :activities => { :one => "atividade", :other => "atividades" },
        :branches => { :one => "branch", :other => "branches" },
        :authors => { :one => "autor", :other => "autores" },
        :name => %Q{Nome <small>(ex "{{name}}-sandbox", "conserto-performance" etc.)</small>},
        :btn_clone => "Clonar Repositório",
        :back => "Retornar ao Repositório",
        :show_page_title => "{{repo}} em {{title}}",
        :show_title => "repositório &quot;{{repo}}&quot; em {{title}}",
        :activities => "Atividades",
        :clone_of => "Clone de",
        :created => "Criado",
        :btn_request => "Requisitar Merge",
        :btn_add_committer => "Adicionar Committer",
        :btn_delete_repo => "Apagar Repositório",
        :committers => "Committers",
        :remove => "Remover",
        :create_title => lambda { |this, clone, project| 
          "Criar um clone de #{this.link_to( h(clone.name), this.send(:project_repository_path, project, clone) )} <small>em #{this.link_to h(project.title), this.send(:project_path, project)}</small>"
        },
        :clone_note => %Q{
          <em><strong>Nota:</strong> Clones de repositório que não tiverem atividade
          dentro de 7 dias são automaticamente removidos (para que o projeto não acabe com
          muitos repositórios vazios), então é uma boa idéia esperar para criar o clone
          aqui até que tenha alguma coisa para gravar nele.</em>
        },
      },
      :projects => {
        :title => "Projetos",
        :back => "Voltar à tela de edição",
        :hint => %Q{São permitidos <a href="http://daringfireball.net/projects/markdown/">Markdown</a> e HTML básico},
        :categories => "Categorias",
        :delete => "Apagar projeto",
        :delete_title => "Por favor, confirme apagar o {{title}}",
        :delete_message => "Uma vez que o botão for pressionado o projeto será apagado",
        :delete_btn => "SIM, tenho certeza que quero apagar este projeto permanentemente",
        :edit => "Editar projeto",
        :update_title => "Atualizar {{link}}",
        :new => "Novo projeto",
        :popular => "Categorias Populares",
        :new_title => "Criar um novo projeto",
        :new_hint => %Q(Um repositório "mainline" padrão será criado junto com o projeto, permitindo que você comece a fazer commits imediatamente.),
        :create => "Criar projeto",
        :settings => "Configurações do Projeto",
        :labels => "Etiquetas",
        :license => "Licença",
        :owner => "Criador",
        :created => "Criado",
        :website => "Site em ",
        :mailing => "Lista de Discussão em ",
        :bugtracker => "Gerenciador de Bugs em ",
        :repos => "Repositórios",
      },
      :merges => {
        :info => {
          :target_repos => "O repositório onde você acha que este deve ser mesclado com",
          :target_branch => "O branch de destino onde quer que suas mudanças sejam mescladas",
          :source_branch => "O branch de origem de onde o repositório de destino deve pegar as mudanças para mesclar",
          :proposal => "Uma breve descrição de suas mudanças",
        },
        :summary_tile => "{{source}} requisitou um merge com {{target}}",
        :review => "Revisar requisição de merge &#x2192;",
        :page_title => "Requisições de merge em {{repo}}",
        :hint => %Q{Uma "requisição de merge" é uma notificação de um repositório para outro de que gostaria que suas mudanças fossem mescladas para cima.},
        :no_merge => "Nenhuma requisição de merge ainda",
        :create_title => "Criar uma requisição de merge",
        :create_btn => "Criar requisição de merge",
        :show_title => "Revisando requisição de merge {{source}} &#x2192; \"{{target}}\"",
        :update_btn => "Atualizar requisição de merge",
        :help => "A maneira recomendada para mesclar essas mudanças é puxá-las para um branch local para revisão e então mesclá-las de volta ao branch master:",
        :commits => "Commits que seriam mesclados",
      },
      :committers => {
        :title => "Dá direitos de commit ao repositório {{repo}} para o usuário",
        :login => "Usuários existentes <small>(pesquisa-enquanto-digita)</small>",
        :add => "Adicionar como committer",
      },
      :common => {
        :confirm => "Tem certeza?",
        :create => "Criar",
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
      },
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
        :human => "%A às %d de %B",
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
          :other => 'menos de {{count}} segundos'
        },
        :x_seconds => {
          :one => '1 segundo',
          :other => '{{count}} segundos'
        },
        :less_than_x_minutes => {
          :one => 'menos de um minuto',
          :other => 'menos de {{count}} minutos'
        },
        :x_minutes => {
          :one => '1 minuto',
          :other => '{{count}} minutos'
        },
        :about_x_hours => {
          :one => 'aproximadamente 1 hora',
          :other => 'aproximadamente {{count}} horas'
        },
        :x_days => {
          :one => '1 dia',
          :other => '{{count}} dias'
        },
        :about_x_months => {
          :one => 'aproximadamente 1 mês',
          :other => 'aproximadamente {{count}} meses'
        },
        :x_months => {
          :one => '1 mês',
          :other => '{{count}} meses'
        },
        :about_x_years => {
          :one => 'aproximadamente 1 ano',
          :other => 'aproximadamente {{count}} anos'
        },
        :over_x_years => {
          :one => 'mais de 1 ano',
          :other => 'mais de {{count}} anos'
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
        :user => {
          :one => "Usuário",
          :other => "Usuários" ,
        },
        :merge_request => {
          :one => "Requisição de Merge",
          :other => "Requisições de Merges",
        },
        :project => {
          :one => "Projeto",
          :other => "Projetos",
        },
        :comment => {
          :one => "Comentário",
          :other => "Comentários",
        },
        :repositories => {
          :one => "Repositório",
          :other => "Repositórios",
        }, 
        :keys => {
          :one => "Chave",
          :other => "Chaves",
        },
      },
      :attributes => {
        :user => {
          :login => "Login",
          :email => "E-mail",
          :current_password => "Senha Atual",
          :password => "Senha",
          :password_confirmation => "Confirmação de Senha",
          :created_at => "Criado em",
          :updated_at => "Atualizado em",
          :activation_code => "Código de Ativação",
          :activated_at => "Ativado em",
          :fullname => "Nome Completo",
          :url => "URL",
        },
        :merge_request => {
          :target_repository_id => "Repositório Original",
          :proposal => "Proposta",
          :source_branch => "Branch Destino",
          :target_branch => "Branch Original",
        },
        :project => {
          :title => "Título",
          :description => "Descrição (obrigatório)",
          :slug => "Apelido (para urls, etc.)",
          :license => "Licença",
          :home_url => "URL do Site Principal (ex. RubyForge, etc.)",
          :mailinglist_url => "URL de Lista de Discussão (se tiver)",
          :bugtracker_url => "URL de Gerenciador de Bugs (se tiver)",
          :tag_list => "Categorias (separadas por espaço)",
        },
        :comment => {
          :body => "Comentário",
        },
        :repository => {
          :name => "Nome",
          :ready => "Preparado",
        },
        :keys => {
          :key => "Chave",
          :ready => "Preparado",
        },
      },
      :errors => {
        :template => {
          :header => {
            :one => "{{model}} não pôde ser salvo: 1 erro",
            :other => "{{model}} não pôde ser salvo: {{count}} erros."
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
          :too_long => "é muito longo (não mais do que {{count}} caracteres)",
          :too_short => "é muito curto (não menos do que {{count}} caracteres)",
          :wrong_length => "não é do tamanho correto (precisa ter {{count}} caracteres)",
          :taken => "não está disponível",
          :not_a_number => "não é um número",
          :greater_than => "precisa ser maior do que {{count}}",
          :greater_than_or_equal_to => "precisa ser maior ou igual a {{count}}",
          :equal_to => "precisa ser igual a {{count}}",
          :less_than => "precisa ser menor do que {{count}}",
          :less_than_or_equal_to => "precisa ser menor ou igual a {{count}}",
          :odd => "precisa ser ímpar",
          :even => "precisa ser par"
        }
      }
    }
  }
}