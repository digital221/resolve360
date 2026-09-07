# --
# Kernel/Config/Files/User/ZZZAResolve360.pm - Custom configuration for Résolve360
# --

package Kernel::Config::Files::User::ZZZAResolve360;

use strict;
use warnings;
use utf8;

sub Load {
    my $Self = shift;

    # Core Branding
    $Self->{'ProductName'} = 'Résolve360';
    $Self->{'NotificationSenderName'} = 'Résolve360 Notifications';
    $Self->{'NotificationSenderEmail'} = 'support@digitalfactory.sn';
    $Self->{'NotificationSubjectLostPassword'} = 'Nouveau mot de passe - Résolve360';
    $Self->{'NotificationSubjectLostPasswordToken'} = 'Demande de réinitialisation de mot de passe - Résolve360';

    # Global Default Language
    $Self->{'DefaultLanguage'} = 'fr';
    $Self->{'CustomerDefaultLanguage'} = 'fr';

    # Security & White-labeling
    $Self->{'Secure::DisableBanner'} = 1;

    # Disable OTOBO default agent dashboard widgets
    $Self->{'DashboardBackend'}->{'0200-Image'}->{'Default'} = 0;
    $Self->{'DashboardBackend'}->{'0300-IFrame'}->{'Default'} = 0;
    $Self->{'DashboardBackend'}->{'0405-News'}->{'Default'} = 0;
    $Self->{'DashboardBackend'}->{'0410-RSS'}->{'Default'} = 0;

    # Customer Dashboard Branding & Custom Tiles
    $Self->{'CustomerDashboard::Configuration::Text'} = {
        'WelcomeText' => 'Bienvenue %s, sur votre espace Résolve360.',
        'SubText'     => 'Votre portail de gestion des réclamations est accessible 24h/24 et 7j/7.',
        'Name'        => 'UserFirstname',
    };

    $Self->{'CustomerDashboard::Tiles'}->{'FeaturedLink-01'} = {
        'Config' => {
            'BackgroundImage' => '<OTOBO_CONFIG_Frontend::WebPath>common/img/Dashboard/dashboard_bgfl.png',
            'FooterText'      => 'Découvrir Digital Factory SN >',
            'HeaderText'      => 'Résolve360 | Service Client',
            'Link'            => 'https://www.digitalfactory.sn',
            'MainText'        => 'Résolve360 vous garantit une prise en charge rapide, transparente et conforme de l\'ensemble de vos réclamations bancaires.',
            'NewTab'          => '1',
            'TextColor'       => '#ffffff',
        },
        'Order'    => '2',
        'Template' => 'Dashboard/TileFeaturedLink',
    };

    $Self->{'CustomerDashboard::Tiles'}->{'TicketList-01'} = {
        'Config' => {
            'CompanyTickets' => '0',
            'MaxTickets'     => '9',
            'OrderBy'        => 'Down',
            'SortBy'         => 'Age',
            'StateType'      => '',
            'Text'           => 'Vos dernières réclamations',
        },
        'Module' => 'Kernel::Output::HTML::CustomerDashboard::TileTicketList',
        'Order'  => '3',
    };

    # Disable sample / German tiles on Customer Dashboard
    $Self->{'CustomerDashboard::Tiles'}->{'InfoTile-01'}->{'Order'} = 0;
    $Self->{'CustomerDashboard::Tiles'}->{'PlainText-01'}->{'Order'} = 0;
    $Self->{'CustomerDashboard::Tiles'}->{'PlainPicture-01'}->{'Order'} = 0;
    $Self->{'CustomerDashboard::Tiles'}->{'ToolBox-01'}->{'Order'} = 0;

    return 1;
}

1;
