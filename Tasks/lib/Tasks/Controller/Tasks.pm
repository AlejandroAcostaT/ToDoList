package Tasks::Controller::Tasks;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Expo::Controller::Books - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Expo::Controller::Books in Books.');
}

=head2 list

Fetch all book objects and pass to books/list.tt2 in stash to be displayed

=cut

sub list :Local {
    # Retrieve the usual Perl OO '$self' for this object. $c is the Catalyst
    # 'Context' that's used to 'glue together' the various components
    # that make up the application
    my ($self, $c) = @_;

    # Retrieve all of the book records as book model objects and store in the
    # stash where they can be accessed by the TT template
    # $c->stash(books => [$c->model('DB::Book')->all]);
    # But, for now, use this code until we create the model later
    $c->stash(tasks => [$c->model('DB::Task')->search({}, {order_by => 'state ASC, created ASC'})]);

    # Set the TT template to use.  You will almost always want to do this
    # in your action methods (action methods respond to user input in
    # your controllers).
    $c->stash(template => 'tasks/list.tt2');
}

=head2 url_create

Create a book with the supplied title, rating, and author

=cut

sub url_create :Chained('base'):PathPart('url_create') :Args(1) {
    # In addition to self & context, get the title, rating, &
    # author_id args from the URL.  Note that Catalyst automatically
    # puts the first 3 arguments worth of extra information after the 
    # "/<controller_name>/<action_name/" into @_ because we specified
    # "Args(3)".  The args are separated  by the '/' char on the URL.
    my ($self, $c, $title) = @_;


    # Call create() on the book model object. Pass the table
    # columns/field values we want to set as hash values
    my $task = $c->model('DB::Task')->create({
            title  => $title,
            state => 0
       });

    # Add a record to the join table for this book, mapping to
    # appropriate author
    # Note: Above is a shortcut for this:
    # $book->create_related('book_authors', {author_id => $author_id});

    # Assign the Book object to the stash for display and set template
    $c->stash(task     => $task,
              template => 'tasks/create_done.tt2');

    # Disable caching for this page
    $c->response->header('Cache-Control' => 'no-cache');
}

=head2 base

Can place common logic to start chained dispatch here

=cut

sub base :Chained('/') :PathPart('tasks') :CaptureArgs(0) {
    my ($self, $c) = @_;

    # Store the ResultSet in stash so it's available for other methods
    $c->stash(resultset => $c->model('DB::Task'));

    # Print a message to the debug log
    $c->log->debug('*** INSIDE BASE METHOD ***');
}

=head2 form_create
    
Display form to collect information for book to create

=cut

sub form_create :Chained('base') :PathPart('form_create') :Args(0) {
    my ($self, $c) = @_;

    # Set the TT template to use
    $c->stash(template => 'tasks/form_create.tt2');
}

=head2 form_create_do

Take information from form and add to database

=cut

sub form_create_do :Chained('base') :PathPart('form_create_do') :Args(0) {
    my ($self, $c) = @_;

    # Retrieve the values from the form
    my $title     = $c->request->params->{title}     || 'N/A';

    # Create the task
    my $task = $c->model('DB::Task')->create({
            title   => $title,
            state   => 0
        });
    # Handle relationship with author
    # Note: Above is a shortcut for this:
    # $book->create_related('book_authors', {author_id => $author_id});

    # Store new model object in stash and set template
    $c->stash(task     => $task,
              template => 'tasks/create_done.tt2');
}

=head2 object

Fetch the specified book object based on the book ID and store
it in the stash

=cut

sub object :Chained('base') :PathPart('id') :CaptureArgs(1) {
    # $id = primary key of book to delete
    my ($self, $c, $id) = @_;

    # Find the book object and store it in the stash
    $c->stash(object => $c->stash->{resultset}->find($id));

    # Make sure the lookup was successful.  You would probably
    # want to do something like this in a real app:
    #   $c->detach('/error_404') if !$c->stash->{object};
    die "Tarea #$id no fue encontrada!" if !$c->stash->{object};

    # Print a message to the debug log
    $c->log->debug("*** INSIDE OBJECT METHOD for obj id=$id ***");
}

=head2 delete

Delete a book

=cut

sub delete :Chained('object') :PathPart('delete') :Args(0) {
    my ($self, $c) = @_;

    # Use the book object saved by 'object' and delete it along
    # with related 'book_author' entries
    $c->stash->{object}->delete;

    # Set a status message to be displayed at the top of the view
    $c->stash->{status_msg} = "Tarea Eliminada.";

    # Forward to the list action/method in this controller
    $c->forward('list');
}

=head2 complete

complete a task

=cut

sub complete :Chained('object') :PathPart('complete') :Args(0) {
    my ($self, $c) = @_;

    # Use the book object saved by 'object' and delete it along
    # with related 'book_author' entries
    my $tsk = $c->stash->{object};
    
    $tsk->update({state => 1, updated => DateTime->now});
    # Set a status message to be displayed at the top of the view
    $c->stash->{status_msg} = "Tarea Completada.";

    # Forward to the list action/method in this controller
    $c->forward('list');
}

=head2 complete

complete a task

=cut

sub uncomplete :Chained('object') :PathPart('uncomplete') :Args(0) {
    my ($self, $c) = @_;

    # Use the book object saved by 'object' and delete it along
    # with related 'book_author' entries
    my $tsk = $c->stash->{object};
    
    $tsk->update({state => 0, updated => DateTime->now});
    # Set a status message to be displayed at the top of the view
    $c->stash->{status_msg} = "Tarea Desmarcada.";

    # Forward to the list action/method in this controller
    $c->forward('list');
}

=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
