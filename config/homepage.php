<?php /* Template Name: Homepage */ ?>
<?php get_header(); ?>

  <section class="content-area">
    <div class="container">
      <div class="hero" aria-label="Introduction">
          <div class="heading">
            <h1 class="sr-only"><span id="introduction">Welcome to the City of Toronto's Open Data Portal</span></h1>
          </div>
          <div class="row">
            <div class="col-md-6 offset-md-3">

              <form class="form-inline" role="search">
                <div class="input-group">
                  <label for="search" class="sr-only">Search Dataset Catalogue</label>
                  <input type="text" class="form-control" name="search" id="search" placeholder="Search datasets"/>
                  <span class="input-group-btn">
                    <button class="btn btn-secondary" type="submit">Search</button>
                  </span>
                </div>
              </form>


            </div>
          </div>
        </div>
      </div>

      <section id="about" aria-label="About City of Toronto Open Data">
        <div id="content"></div>
        <div class="container">
          <div class="row">
            <div class="col-md-5">
              <h2 class="heading">About City of Toronto Open Data</h2>
              <p>Open Government is about improving the delivery of services, making information more accessible and supporting initiatives that build public trust in government. It is guided by four principles of transparency, participation, accountability, and accessibility and supported by three pillars of Open Data, Open Information, and Open Engagement.</p>
              <a class="btn btn-md" href="/about/">Learn more about Open Data</a>
            </div>

            <div class="col-md-6 offset-md-1">
              <h2>Latest Datasets</h2>
              <ul class="newsfeed"></ul>
              <a class="btn btn-md" href="/catalogue/">Explore the Catalogue</a>
            </div>
          </div>
        </div>
      </section>

    </div>
  </section>
</div><!-- end row -->
</div><!-- ends container-->

<script type="text/javascript">
    jQuery(document).ready(function($) { init(); });
</script>

<?php get_footer(); ?>
